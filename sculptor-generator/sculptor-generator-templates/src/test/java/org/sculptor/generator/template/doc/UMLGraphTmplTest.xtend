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
package org.sculptor.generator.template.doc

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension;
import org.eclipselabs.xtext.utils.unittesting.XtextTest
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.^extension.ExtendWith;
import org.sculptor.dsl.tests.SculptordslInjectorProvider
import org.sculptor.generator.ext.UmlGraphHelper
import org.sculptor.generator.test.GeneratorModelTestFixtures

import static org.junit.jupiter.api.Assertions.*;

import static extension org.sculptor.generator.test.GeneratorTestExtensions.*

@ExtendWith(typeof(InjectionExtension))
@InjectWith(typeof(SculptordslInjectorProvider))
class UMLGraphTmplTest extends XtextTest {
	
	@Inject
	var GeneratorModelTestFixtures generatorModelTestFixtures

	var UMLGraphTmpl umlGraphTmpl
	var extension UmlGraphHelper umlGraphHelper

	@BeforeEach
	def void setup() {
		generatorModelTestFixtures.setupInjector(typeof(UMLGraphTmpl), typeof(UmlGraphHelper))
		generatorModelTestFixtures.setupModel("generator-tests/doc/model.btdesign")
		
		umlGraphTmpl = generatorModelTestFixtures.getProvidedObject(typeof(UMLGraphTmpl))
		umlGraphHelper = generatorModelTestFixtures.getProvidedObject(typeof(UmlGraphHelper))
	}

	@Test
	def void assertModel() {
		val app = generatorModelTestFixtures.app
		
		assertEquals(2, app.modules.size)
	}

	@Test
	def void testEntityDot() {
		val app = generatorModelTestFixtures.app
		
		val code = umlGraphTmpl.startContent(app, app.visibleModules.toSet, 0, "entity")
		assertNotNull(code)

        code.assertContainsConsecutiveFragments(#[
            'edge [arrowhead = "none"]',
            'edge [arrowtail="none" arrowhead = "open" headlabel="" taillabel="" labeldistance="2.0" labelangle="-30"]'
        ])
	}

}
