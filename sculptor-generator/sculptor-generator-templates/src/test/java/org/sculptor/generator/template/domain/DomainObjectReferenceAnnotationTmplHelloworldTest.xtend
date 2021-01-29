/*
 * Copyright 2013 The Sculptor Project Team, including the original 
 * author or authors.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.sculptor.generator.template.domain

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension;
import org.eclipselabs.xtext.utils.unittesting.XtextTest
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.^extension.ExtendWith;
import org.sculptor.dsl.tests.SculptordslInjectorProvider
import org.sculptor.generator.configuration.Configuration
import org.sculptor.generator.configuration.ConfigurationProviderModule
import org.sculptor.generator.test.GeneratorModelTestFixtures

import static org.junit.jupiter.api.Assertions.*;

import static extension org.sculptor.generator.test.GeneratorTestExtensions.*

@ExtendWith(typeof(InjectionExtension))
@InjectWith(typeof(SculptordslInjectorProvider))
class DomainObjectReferenceAnnotationTmplHelloworldTest extends XtextTest {

	@Inject
	var GeneratorModelTestFixtures generatorModelTestFixtures

	var DomainObjectReferenceAnnotationTmpl domainObjectReferenceAnnotationTmpl

	@BeforeEach
	def void setup() {
		System.setProperty(Configuration.PROPERTIES_LOCATION_PROPERTY,
			"generator-tests/helloworld/sculptor-generator.properties")
		generatorModelTestFixtures.setupInjector(typeof(DomainObjectReferenceAnnotationTmpl))
		generatorModelTestFixtures.setupModel("generator-tests/helloworld/model.btdesign")

		domainObjectReferenceAnnotationTmpl = generatorModelTestFixtures.getProvidedObject(
			typeof(DomainObjectReferenceAnnotationTmpl))
	}

	@AfterEach
	def void clearSystemProperties() {
		System.clearProperty(ConfigurationProviderModule.PROPERTIES_LOCATION_PROPERTY);
	}

	@Test
	def void testAppTransformation() {
		val app = generatorModelTestFixtures.app
		assertNotNull(app)

		assertEquals(1, app.modules.size)
	}

	@Test
	def void assertOneToManyWithCascadeTypeRemoveInPlanetBaseForReferenceMoons() {
		val app = generatorModelTestFixtures.app
		assertNotNull(app)

		val module = app.modules.namedElement("milkyway")
		assertNotNull(module)

		val planet = module.domainObjects.namedElement("Planet")
		val moons = planet.references.namedElement("moons")
		assertNotNull(moons)

		val code = domainObjectReferenceAnnotationTmpl.oneToManyJpaAnnotation(moons)
		assertNotNull(code)
		assertContains(code, '@javax.persistence.OneToMany')
		assertContains(code, 'cascade=javax.persistence.CascadeType.REMOVE')
		assertContains(code, 'orphanRemoval=true')
		assertContains(code, 'mappedBy="planet"')
		assertContains(code, 'fetch=javax.persistence.FetchType.EAGER')
	}

	@Test
	def void assertManyToOneInMoonForPlanet() {
		val app = generatorModelTestFixtures.app
		assertNotNull(app)

		val module = app.modules.namedElement("milkyway")
		assertNotNull(module)

		val moon = module.domainObjects.namedElement("Moon")
		val planet = moon.references.namedElement("planet")
		assertNotNull(planet)

		val code = domainObjectReferenceAnnotationTmpl.manyToOneJpaAnnotation(planet)
		assertNotNull(code)
		assertContains(code, '@javax.persistence.ManyToOne')
		assertContains(code, 'optional=false')
		assertContains(code, '@javax.persistence.JoinColumn')
		assertContains(code, 'name="PLANET"')
		assertContains(code, 'foreignKey=@javax.persistence.ForeignKey(name="FK_MOON_PLANET")')
	}

}
	