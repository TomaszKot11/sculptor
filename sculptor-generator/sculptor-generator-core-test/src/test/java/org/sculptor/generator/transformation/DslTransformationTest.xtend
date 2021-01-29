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
package org.sculptor.generator.transformation

import javax.inject.Provider
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.sculptor.dsl.sculptordsl.DslApplication
import org.sculptor.dsl.sculptordsl.DslInheritanceType
import org.sculptor.dsl.sculptordsl.SculptordslFactory
import org.sculptor.generator.chain.ChainOverrideAwareInjector
import org.sculptor.generator.configuration.Configuration
import org.sculptor.generator.ext.Helper
import org.sculptor.generator.transform.DslTransformation
import sculptormetamodel.Entity
import sculptormetamodel.InheritanceType
import sculptormetamodel.Service
import sculptormetamodel.ValueObject

import static org.junit.jupiter.api.Assertions.*;

import static extension org.sculptor.generator.test.GeneratorTestExtensions.*

class DslTransformationTest {

	static val SculptordslFactory FACTORY = SculptordslFactory.eINSTANCE

	extension Helper helper

	var DslApplication model
	var Provider<DslTransformation> dslTransformProvider

	@BeforeEach
	def void setupDslModel() {

		// Activate cartridge 'test' with transformation extensions 
		System.setProperty(Configuration.PROPERTIES_LOCATION_PROPERTY,
			"generator-tests/transformation/sculptor-generator.properties")

		val injector = ChainOverrideAwareInjector.createInjector(typeof(DslTransformation))
		helper = injector.getInstance(typeof(Helper))
		dslTransformProvider = injector.getProvider(typeof(DslTransformation))

		model = createDslModel
	}

	@Test
	def testTransformDslModel() {
		val transformation = dslTransformProvider.get
		val app = transformation.transform(model)
		assertNotNull(app)
		assertEquals("appName", app.name)
		assertEquals("com.acme", app.basePackage)
		assertEquals("appDoc", app.doc)

		assertOneAndOnlyOne(app.modules, "module1Name", "module2Name")
		for (i : 1..2) {
			val module = app.modules.get(i - 1)
			assertEquals("module" + i + "Name", module.name)
			assertEquals("com.acme.module" + i, module.basePackage)
			assertEquals("module" + i + "Doc", module.doc)
			assertEquals("module" + i + "Value2", getHint(module, "key2"))

			assertEquals(2, module.services.size)
			for (j : 1 .. 2) {
				val service = module.services.get(j - 1)
				assertEquals("service" + i + j + "Name", service.name)
				assertEquals("service" + i + j + "Doc", service.doc)
				assertEquals("service" + i + j + "Value2", getHint(service, "key2"))
				assertFalse(service.localInterface)
				assertFalse(service.remoteInterface)
			}
		}
	}

	def getTransformedApp() {
		val transformation = dslTransformProvider.get
		transformation.transform(model)
	}

	@Test
	def void testTransformEntity() {
		val module = transformedApp.modules.namedElement("module1Name")
		assertNotNull(module)
		assertEquals(2, module.domainObjects.size)
		val Entity entity1 = module.domainObjects.findFirst[name == "Entity1"] as Entity
		assertNotNull(entity1)
		entity1 => [
			assertEquals("Documentation1", doc)
			assertEquals("some.com.package", getPackage())			
			assertEquals("hint1", hint)
			assertEquals(false, auditable)
			assertEquals(false, cache)
			assertEquals("SOME_TABLE", databaseTable)
			assertNull(belongsToAggregate)
			assertTrue(aggregateRoot)
			assertEquals("validator1", validate)
			assertEquals(true, gapClass)
			assertEquals("disc1", discriminatorColumnValue)
			assertEquals(InheritanceType.JOINED, inheritance.type)
			assertNull(extendsName)
			assertEquals(0, attributes.size)
			assertEquals(0, references.size)
			assertEquals(0, operations.size)
			assertEquals(0, traits.size)
			assertNotNull(repository)
			assertEquals("repository1Name", repository.name)
			
			// TODO: Verify references, attributes, etc
		]
	}

	@Test
	def void testTransformValueObject() {
		val module = transformedApp.modules.namedElement("module1Name")
		val ValueObject vo1 = module.domainObjects.findFirst[name == "ValueObject1"] as ValueObject
		assertNotNull(vo1)
		vo1 => [
			assertEquals("ValueObject doc1", doc)
			
			// TODO
		]
	}

	def createDslModel() {
		val service11 = FACTORY.createDslService
		service11.name = "service11Name"
		service11.doc = "service11Doc"
		service11.hint = "key1 = service11Value1 , notRemote, notLocal , key2 = service11Value2 , key3"

		val dependency1 = FACTORY.createDslDependency
		dependency1.dependency = service11

		val service12 = FACTORY.createDslService
		service12.name = "service12Name"
		service12.doc = "service12Doc"
		service12.hint = "key1 = service12Value1 , notRemote, notLocal , key2 = service12Value2 , key3"
		service12.dependencies.addAll(dependency1)

		val repository1 = FACTORY.createDslRepository
		repository1.setName("repository1Name")
		repository1.setDoc("repository1Doc")

		val entity1 = FACTORY.createDslEntity => [
			name = "Entity1"
			doc = "Documentation1"
			setPackage("some.com.package")
			hint = "hint1"
			setAbstract(true)
			notOptimisticLocking = true
			notAuditable = true
			cache = false
			databaseTable = "SOME_TABLE"
			belongsTo = null
			notAggregateRoot = false
			validate = "validator1"
			gapClass = true
			discriminatorValue = "disc1"
			inheritanceType = DslInheritanceType.JOINED
			repository = repository1
		]

		val vo1 = FACTORY.createDslValueObject => [
			name = "ValueObject1"
			doc = "ValueObject doc1"
			setPackage("some.com.package")
			hint = "vohint"
			
			// TODO
		]

		val module1 = FACTORY.createDslModule
		module1.setBasePackage("com.acme.module1")
		module1.setName("module1Name")
		module1.setDoc("module1Doc")
		module1.setHint("key1 = module1Value1 , key2 = module1Value2 , key3")
		module1.services.addAll(service11, service12)
		module1.domainObjects.addAll(entity1, vo1)


		val service21 = FACTORY.createDslService
		service21.name = "service21Name"
		service21.doc = "service21Doc"
		service21.hint = "key1 = service21Value1 , notRemote, notLocal , key2 = service21Value2 , key3"

		val dependency2 = FACTORY.createDslDependency
		dependency2.dependency = service11	// from module 1

		val service22 = FACTORY.createDslService
		service22.name = "service22Name"
		service22.doc = "service22Doc"
		service22.hint = "key1 = service22Value1 , notRemote, notLocal , key2 = service22Value2 , key3"
		service22.dependencies.addAll(dependency2)

		val module2 = FACTORY.createDslModule
		module2.setBasePackage("com.acme.module2")
		module2.setName("module2Name")
		module2.setDoc("module2Doc")
		module2.setHint("key1 = module2Value1 , key2 = module2Value2 , key3")
		module2.services.addAll(service21, service22)
		
		val app = FACTORY.createDslApplication
		app.setBasePackage("com.acme")
		app.setName("appName")
		app.setDoc("appDoc")
		app.modules.addAll(module1, module2)

		app
	}

	@Test
	def void testServiceDependency() {
		val module = transformedApp.modules.namedElement("module1Name")
		val Service service = module.services.findFirst[name == "service12Name"]
		assertNotNull(service)
		service => [
			assertEquals(1, serviceDependencies.size)
			assertEquals("service11Name", serviceDependencies.get(0).name)
		]
	}

	@Test
	def void testCrossModuleServiceDependency() {
		val module = transformedApp.modules.namedElement("module2Name")
		val Service service = module.services.findFirst[name == "service22Name"]
		assertNotNull(service)
		service => [
			assertEquals(1, serviceDependencies.size)
			assertEquals("service11Name", serviceDependencies.get(0).name)
		]
	}

}