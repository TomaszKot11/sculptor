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
package org.sculptor.generator.test

import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.IOException
import java.util.regex.Pattern
import org.eclipse.emf.common.util.EList
import sculptormetamodel.NamedElement

import static org.junit.jupiter.api.Assertions.*;

/**
 * Extensions used in generator tests
 */
class GeneratorTestExtensions {

	protected static val SYSTEM_ATTRIBUTES = newImmutableSet("id", "uuid", "version",
		"createdBy", "createdDate", "updatedBy", "updatedDate", "lastUpdated", "lastUpdatedBy")

	// TODO: Move into helpers?
	def static <T extends NamedElement> namedElement(EList<T> list, String toFindName) {
		list.findFirst[name == toFindName]
	}

	def static void assertContains(String text, String subString) {
		assertTrue(text.contains(subString), "text does not contain expected substring: " + subString);
	}

	/**
      * Assert that the given text contains the regular expression, using multiline matching
      */
	def static void assertMatchesRegexp(String text, String regexp) {
		val p = Pattern.compile(regexp, Pattern.MULTILINE);
		assertTrue(p.matcher(text).find(), "Text did not contain pattern \"" + regexp + "\"");
	}

	/**
      * Assert that the given text contains the given text fragments, separated by whitespace (including newline).
      */
	def static void assertContainsConsecutiveFragments(String text, String[] fragments) {
		val sb = new StringBuilder();

		for (String fragment : fragments) {
			sb.append(Pattern.quote(fragment) + "\\s*");
		}
		assertMatchesRegexp(text, sb.toString());
	}

	def static void assertNotContains(String text, String subStr) {
		assertFalse(text.contains(subStr), "Text contained substring \"" + subStr + "\"");
	}

	/**
	 * @return contents of file as a String
	 */
	def static String getText(File textFile) throws IOException {
		val sb = new StringBuffer();
		val in = new BufferedReader(new FileReader(textFile));
		var String str;
		while ((str = in.readLine()) !== null) {
			sb.append(str);
			sb.append("\n");
		}
		in.close();
		return sb.toString();
	}

	def static <NE extends NamedElement> void assertOneAndOnlyOne(EList<NE> listOfNamedElements, String... expectedNames) {
		val expectedNamesList = newArrayList(expectedNames)

		// Remove the names of unexpected system attributes 
		val actualNames = listOfNamedElements.map[ne|ne.name].filter[name|
			expectedNamesList.contains(name) || !SYSTEM_ATTRIBUTES.contains(name)].toList

		assertTrue(actualNames.sort.equals(expectedNamesList.sort)
			, "Expected: " + expectedNamesList + ", Actual: " + actualNames)
	}

	def static <NE extends NamedElement> void assertOneAndOnlyOneWithoutFilter(EList<NE> listOfNamedElements, String... expectedNames) {
		val expectedNamesList = newArrayList(expectedNames)

		val actualNames = listOfNamedElements.map[ne|ne.name].toList

		assertTrue(actualNames.sort.equals(expectedNamesList.sort)
			, "Expected: " + expectedNamesList + ", Actual: " + actualNames)
	}

}
