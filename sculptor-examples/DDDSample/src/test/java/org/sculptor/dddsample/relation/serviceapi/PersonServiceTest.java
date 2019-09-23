package org.sculptor.dddsample.relation.serviceapi;

import org.junit.Test;
import org.sculptor.dddsample.relation.domain.House;
import org.sculptor.dddsample.relation.domain.Person;
import org.sculptor.dddsample.relation.domain.PersonProperties;
import org.sculptor.dddsample.relation.serviceapi.PersonService;
import org.sculptor.framework.accessapi.ConditionalCriteria;
import org.sculptor.framework.accessapi.ConditionalCriteriaBuilder;
import org.sculptor.framework.domain.PagingParameter;
import org.sculptor.framework.test.AbstractDbUnitJpaTests;
import org.springframework.beans.factory.annotation.Autowired;

import javassist.expr.Instanceof;

import static org.junit.Assert.*;

import java.util.Collection;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 * Spring based transactional test with DbUnit support.
 */
public class PersonServiceTest extends AbstractDbUnitJpaTests implements PersonServiceTestBase {

	@Autowired
	private PersonService personService;

	@PersistenceContext(unitName = "DDDSampleEntityManagerFactory")
	private EntityManager entityManager;

	@Override
	protected String getDataSetFile() {
		return "dbunit/TestData.xml";
	}

	@Test
	public void testFindById() throws Exception {
		Person feromon = personService.findById(getServiceContext(), 103l);
		assertEquals("Feromon", feromon.getFirst());
		assertEquals("Smradoch", feromon.getSecondName());
	}

	@Test
	public void testFindAll() throws Exception {
		List<Person> all = personService.findAll(getServiceContext());
		assertEquals(4, all.size());
		boolean was101 = false;
		for (Person p : all) {
			if (p.getId().equals(101l)) {
				Collection<House> owningNoRel = p.getOwningUni();
				assertEquals(3, owningNoRel.size());
				Collection<House> relatedNoRel = p.getRelatedUni();
				// Should be 0 no 3
				assertEquals(3, relatedNoRel.size());
				Collection<House> otherNoRel = p.getOtherUni();
				// Should be 0 no 3
				assertEquals(3, otherNoRel.size());
				was101 = true;
			}
		}
		assertTrue(was101);
	}

	@Test
	@Override
	public void testSave() throws Exception {
		House firstHouse = new House();
		firstHouse.setName("Vyrocnik");
		firstHouse.setStreet("Atomic");
		firstHouse.setNumber("1123");
		firstHouse.setTown("Plymouth");
		firstHouse.setZipCode("A-923754");
		firstHouse.setState("Small Britain");

		House secondHouse = new House();
		secondHouse.setName("Kukacnik");
		secondHouse.setStreet("Quark");
		secondHouse.setNumber("893");
		secondHouse.setTown("Cardiff");
		secondHouse.setState("Small Britain");
		secondHouse.setZipCode("B-3478");
		secondHouse.setNumberOfFloors(1);
		secondHouse.setHouseFootprint(947);
		secondHouse.setLandFieldSize(1837);

		Person p = new Person();
		p.setFirst("Newman");
		p.setSecondName("Elemental");
		p.addOwningUni(firstHouse);
		p.addOwningUni(secondHouse);
		Person stored = personService.save(getServiceContext(), p);
		entityManager.clear();

		// All will have 2 items not only OwningNoRel
		Person fetched = personService.findById(getServiceContext(), stored.getId());

		Collection<House> owningUni = fetched.getOwningUni();
		assertEquals(2, owningUni.size());

		// This is WRONG - should be 0
		Collection<House> relatedUni = fetched.getRelatedUni();
		assertEquals(2, relatedUni.size());

		// This is WRONG - should be 0
		Collection<House> otherUni = fetched.getOtherUni();
		assertEquals(2, otherUni.size());
	}

	@Test
	@Override
	public void testDelete() throws Exception {
		int personCount = countRowsInTable(Person.class);
		Person person = personService.findById(getServiceContext(), 103l);
		personService.delete(getServiceContext(), person);
		int personCount2 = countRowsInTable(Person.class);
		assertEquals("Person with ID 103 not removed", 1, personCount - personCount2);
	}

	@Test
	public void testReadOnly() throws Exception {
		List<ConditionalCriteria> condition = ConditionalCriteriaBuilder.criteriaFor(Person.class)
				.withProperty(PersonProperties.id()).greaterThan(0)
				.build();
		List<Person> persons = personService.findByCondition(getServiceContext(), condition, PagingParameter.noLimits()).getValues();
		persons.stream().forEach(p -> p.setSecondName("READ_WRITE"));
		entityManager.flush();
		entityManager.clear();

		List<ConditionalCriteria> conditionRo = ConditionalCriteriaBuilder.criteriaFor(Person.class)
				.withProperty(PersonProperties.id()).greaterThan(0)
				.readOnly()
				.build();
		List<Person> personsRo = personService.findByCondition(getServiceContext(), conditionRo, PagingParameter.noLimits()).getValues();
		personsRo.stream().forEach(p -> p.setSecondName("NEW_VALUE"));
		entityManager.flush();
		entityManager.clear();

		List<Person> allPersons = personService.findAll(getServiceContext());
		allPersons.stream().forEach(p -> assertEquals("READ_WRITE", p.getSecondName()));
	}

	@Test
	public void testScrolleable() throws Exception {
		// Scroll only
		List<ConditionalCriteria> condition = ConditionalCriteriaBuilder.criteriaFor(Person.class)
				.withProperty(PersonProperties.id()).greaterThan(0)
				.orderBy(PersonProperties.id())
				.scroll()
				.build();
		List<Person> persons = personService.findByCondition(getServiceContext(), condition, PagingParameter.rowAccess(0, 2)).getValues();
		try {
			persons.size();
			fail("Exception not thrown");
		} catch (UnsupportedOperationException uoe) {
			assertTrue(uoe instanceof UnsupportedOperationException);
		}
		persons.stream().forEach(p -> p.setSecondName("SCROLL"));
		entityManager.flush();
		entityManager.clear();

		// Scroll only with readOnly
		List<ConditionalCriteria> conditionRo = ConditionalCriteriaBuilder.criteriaFor(Person.class)
				.withProperty(PersonProperties.id()).greaterThan(0)
				.orderBy(PersonProperties.id())
				.readOnly()
				.scroll()
				.build();
		List<Person> personsRo = personService.findByCondition(getServiceContext(), conditionRo, PagingParameter.rowAccess(0, 2)).getValues();
		try {
			persons.size();
			fail("Exception not thrown");
		} catch (UnsupportedOperationException uoe) {
			assertTrue(uoe instanceof UnsupportedOperationException);
		}
		personsRo.stream().forEach(p -> p.setSecondName("NEW_VALUE"));
		entityManager.flush();
		entityManager.clear();

		List<Person> allPersons = personService.findAll(getServiceContext());
		long countScroll = allPersons.stream().filter(p -> p.getSecondName().equals("SCROLL")).count();
		assertEquals(2, countScroll);

		long countNew = allPersons.stream().filter(p -> p.getSecondName().equals("NEW_VALUE")).count();
		assertEquals(0, countNew);
	}

	@Override
	public void testFindByCondition() throws Exception {
	}
}
