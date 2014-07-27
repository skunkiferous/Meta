/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.demo

import com.blockwithme.meta.Property
import com.blockwithme.meta.beans._Bean
import com.blockwithme.meta.beans._CollectionBean
import java.util.Collection
import static org.junit.Assert.*
import org.junit.Test
import com.blockwithme.meta.demo.impl.CollectionOwnerProvider
import java.util.Set
import java.util.List
import com.blockwithme.meta.beans.CollectionBeanConfig

/**
 * Tests the generation of Collection properties.
 * The implementation of the individual Collections is tested elsewhere.
 *
 * @author monster
 *
 */
class CollectionTest {
	static val hierarchy = Meta.BUILDER.newHierarchy(Meta.PACKAGE, Meta.PACKAGE)

	@Test
	def void testCreation() {
		val co = new CollectionOwnerProvider().get

		assertEquals("co.rawDefaultSet", null, co.rawDefaultSet)
		assertEquals("co.rawUnorderedSet", null, co.rawUnorderedSet)
		assertEquals("co.rawOrderedSet", null, co.rawOrderedSet)
		assertEquals("co.rawSortedSet", null, co.rawSortedSet)
		assertEquals("co.rawHashSet", null, co.rawHashSet)
		assertEquals("co.rawList", null, co.rawList)
		assertEquals("co.rawFixedSizeList", null, co.rawFixedSizeList)
		assertEquals("co.rawNullList", null, co.rawNullList)
	}

	@Test
	def void testLazyInit() {
		val co = new CollectionOwnerProvider().get

		assertNotNull("co.defaultSet", co.defaultSet)
		assertNotNull("co.unorderedSet", co.unorderedSet)
		assertNotNull("co.orderedSet", co.orderedSet)
		assertNotNull("co.sortedSet", co.sortedSet)
		assertNotNull("co.hashSet", co.hashSet)
		assertNotNull("co.list", co.list)
		assertNotNull("co.fixedSizeList", co.fixedSizeList)
		assertNotNull("co.nullList", co.nullList)

		assertNotNull("co.rawDefaultSet", co.rawDefaultSet)
		assertNotNull("co.rawUnorderedSet", co.rawUnorderedSet)
		assertNotNull("co.rawOrderedSet", co.rawOrderedSet)
		assertNotNull("co.rawSortedSet", co.rawSortedSet)
		assertNotNull("co.rawHashSet", co.rawHashSet)
		assertNotNull("co.rawList", co.rawList)
		assertNotNull("co.rawFixedSizeList", co.rawFixedSizeList)
		assertNotNull("co.rawNullList", co.rawNullList)

		assertTrue("co.defaultSet.empty", co.defaultSet.empty)
		assertTrue("co.unorderedSet.empty", co.unorderedSet.empty)
		assertTrue("co.orderedSet.empty", co.orderedSet.empty)
		assertTrue("co.sortedSet.empty", co.sortedSet.empty)
		assertTrue("co.hashSet.empty", co.hashSet.empty)
		assertTrue("co.list.empty", co.list.empty)
		assertFalse("co.fixedSizeList.empty", co.fixedSizeList.empty)
		assertTrue("co.nullList.empty", co.nullList.empty)

		assertEquals("co.defaultSet.size", 0, co.defaultSet.size)
		assertEquals("co.unorderedSet.size", 0, co.unorderedSet.size)
		assertEquals("co.orderedSet.size", 0, co.orderedSet.size)
		assertEquals("co.sortedSet.size", 0, co.sortedSet.size)
		assertEquals("co.hashSet.size", 0, co.hashSet.size)
		assertEquals("co.list.size", 0, co.list.size)
		assertEquals("co.fixedSizeList.size", 10, co.fixedSizeList.size)
		assertEquals("co.nullList.size", 0, co.nullList.size)

		assertTrue("co.defaultSet instanceof _CollectionBean", co.defaultSet instanceof _CollectionBean)
		assertTrue("co.unorderedSet instanceof _CollectionBean", co.unorderedSet instanceof _CollectionBean)
		assertTrue("co.orderedSet instanceof _CollectionBean", co.orderedSet instanceof _CollectionBean)
		assertTrue("co.sortedSet instanceof _CollectionBean", co.sortedSet instanceof _CollectionBean)
		assertTrue("co.hashSet instanceof _CollectionBean", co.hashSet instanceof _CollectionBean)
		assertTrue("co.list instanceof _CollectionBean", co.list instanceof _CollectionBean)
		assertTrue("co.fixedSizeList instanceof _CollectionBean", co.fixedSizeList instanceof _CollectionBean)
		assertTrue("co.nullList instanceof _CollectionBean", co.nullList instanceof _CollectionBean)

		assertEquals("co.defaultSet.config", CollectionBeanConfig.UNORDERED_SET, co.defaultSet.config)
		assertEquals("co.unorderedSet.config", CollectionBeanConfig.UNORDERED_SET, co.unorderedSet.config)
		assertEquals("co.orderedSet.config", CollectionBeanConfig.ORDERED_SET, co.orderedSet.config)
		assertEquals("co.sortedSet.config", CollectionBeanConfig.SORTED_SET, co.sortedSet.config)
		assertEquals("co.hashSet.config", CollectionBeanConfig.HASH_SET, co.hashSet.config)
		assertEquals("co.list.config", CollectionBeanConfig.LIST, co.list.config)
		assertTrue("co.fixedSizeList.config.list", co.fixedSizeList.config.list)
		assertEquals("co.fixedSizeList.config.fixedSize", 10, co.fixedSizeList.config.fixedSize)
		assertEquals("co.nullList.config", CollectionBeanConfig.NULL_LIST, co.nullList.config)
	}

	@Test
	def void testClearing() {
		val co = new CollectionOwnerProvider().get

		assertNotNull("co.defaultSet", co.defaultSet)
		assertNotNull("co.unorderedSet", co.unorderedSet)
		assertNotNull("co.orderedSet", co.orderedSet)
		assertNotNull("co.sortedSet", co.sortedSet)
		assertNotNull("co.hashSet", co.hashSet)
		assertNotNull("co.list", co.list)
		assertNotNull("co.fixedSizeList", co.fixedSizeList)
		assertNotNull("co.nullList", co.nullList)

		co.defaultSet = null;
		co.unorderedSet = null;
		co.orderedSet = null;
		co.sortedSet = null;
		co.hashSet = null;
		co.list = null;
		co.fixedSizeList = null;
		co.nullList = null;

		assertEquals("co.rawDefaultSet", null, co.rawDefaultSet)
		assertEquals("co.rawUnorderedSet", null, co.rawUnorderedSet)
		assertEquals("co.rawOrderedSet", null, co.rawOrderedSet)
		assertEquals("co.rawSortedSet", null, co.rawSortedSet)
		assertEquals("co.rawHashSet", null, co.rawHashSet)
		assertEquals("co.rawList", null, co.rawList)
		assertEquals("co.rawFixedSizeList", null, co.rawFixedSizeList)
		assertEquals("co.rawNullList", null, co.rawNullList)
	}

	@Test
	def void testSetFails() {
		val co = new CollectionOwnerProvider().get

		assertNotNull("co.defaultSet", co.defaultSet)
		assertNotNull("co.unorderedSet", co.unorderedSet)
		assertNotNull("co.orderedSet", co.orderedSet)
		assertNotNull("co.sortedSet", co.sortedSet)
		assertNotNull("co.hashSet", co.hashSet)
		assertNotNull("co.list", co.list)
		assertNotNull("co.fixedSizeList", co.fixedSizeList)
		assertNotNull("co.nullList", co.nullList)

		var exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.defaultSet = co.defaultSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.defaultSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.unorderedSet = co.unorderedSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.unorderedSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.orderedSet = co.orderedSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.orderedSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.sortedSet = co.sortedSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.sortedSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.hashSet = co.hashSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.hashSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.list = co.list;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.list = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.fixedSizeList = co.fixedSizeList;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.fixedSizeList = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.nullList = co.nullList;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.nullList = <not null>", exception)

		assertNotNull("co.rawDefaultSet", co.rawDefaultSet)
		assertNotNull("co.rawUnorderedSet", co.rawUnorderedSet)
		assertNotNull("co.rawOrderedSet", co.rawOrderedSet)
		assertNotNull("co.rawSortedSet", co.rawSortedSet)
		assertNotNull("co.rawHashSet", co.rawHashSet)
		assertNotNull("co.rawList", co.rawList)
		assertNotNull("co.rawFixedSizeList", co.rawFixedSizeList)
		assertNotNull("co.rawNullList", co.rawNullList)
	}
}