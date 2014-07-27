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

import com.blockwithme.meta.beans.CollectionBeanConfig
import com.blockwithme.meta.beans._ListBean
import com.blockwithme.meta.beans._SetBean
import com.blockwithme.meta.beans._MapBean
import com.blockwithme.meta.demo.impl.CollectionOwnerProvider
import org.junit.Test

import static org.junit.Assert.*

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
		assertEquals("co.rawRealList", null, co.rawRealList)
		assertEquals("co.rawRealSet", null, co.rawRealSet)
		assertEquals("co.rawIntegerSet", null, co.rawIntegerSet)
		assertEquals("co.rawMap", null, co.rawMap)
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
		assertNotNull("co.realList", co.realList)
		assertNotNull("co.realSet", co.realSet)
		assertNotNull("co.integerSet", co.integerSet)
		assertNotNull("co.map", co.map)

		assertNotNull("co.rawDefaultSet", co.rawDefaultSet)
		assertNotNull("co.rawUnorderedSet", co.rawUnorderedSet)
		assertNotNull("co.rawOrderedSet", co.rawOrderedSet)
		assertNotNull("co.rawSortedSet", co.rawSortedSet)
		assertNotNull("co.rawHashSet", co.rawHashSet)
		assertNotNull("co.rawList", co.rawList)
		assertNotNull("co.rawFixedSizeList", co.rawFixedSizeList)
		assertNotNull("co.rawNullList", co.rawNullList)
		assertNotNull("co.rawRealSet", co.rawRealSet)
		assertNotNull("co.rawRealList", co.rawRealList)
		assertNotNull("co.rawIntegerSet", co.rawIntegerSet)
		assertNotNull("co.rawMap", co.rawMap)

		assertTrue("co.defaultSet.empty", co.defaultSet.empty)
		assertTrue("co.unorderedSet.empty", co.unorderedSet.empty)
		assertTrue("co.orderedSet.empty", co.orderedSet.empty)
		assertTrue("co.sortedSet.empty", co.sortedSet.empty)
		assertTrue("co.hashSet.empty", co.hashSet.empty)
		assertTrue("co.list.empty", co.list.empty)
		assertFalse("co.fixedSizeList.empty", co.fixedSizeList.empty)
		assertTrue("co.nullList.empty", co.nullList.empty)
		assertTrue("co.realList.empty", co.realList.empty)
		assertTrue("co.realSet.empty", co.realSet.empty)
		assertTrue("co.integerSet.empty", co.integerSet.empty)
		assertTrue("co.map.empty", co.map.empty)

		assertEquals("co.defaultSet.size", 0, co.defaultSet.size)
		assertEquals("co.unorderedSet.size", 0, co.unorderedSet.size)
		assertEquals("co.orderedSet.size", 0, co.orderedSet.size)
		assertEquals("co.sortedSet.size", 0, co.sortedSet.size)
		assertEquals("co.hashSet.size", 0, co.hashSet.size)
		assertEquals("co.list.size", 0, co.list.size)
		assertEquals("co.fixedSizeList.size", 10, co.fixedSizeList.size)
		assertEquals("co.nullList.size", 0, co.nullList.size)
		assertEquals("co.realList.size", 0, co.realList.size)
		assertEquals("co.realSet.size", 0, co.realSet.size)
		assertEquals("co.integerSet.size", 0, co.integerSet.size)
		assertEquals("co.map.size", 0, co.map.size)

		assertTrue("co.defaultSet instanceof _SetBean", co.defaultSet instanceof _SetBean)
		assertTrue("co.unorderedSet instanceof _SetBean", co.unorderedSet instanceof _SetBean)
		assertTrue("co.orderedSet instanceof _SetBean", co.orderedSet instanceof _SetBean)
		assertTrue("co.sortedSet instanceof _SetBean", co.sortedSet instanceof _SetBean)
		assertTrue("co.hashSet instanceof _SetBean", co.hashSet instanceof _SetBean)
		assertTrue("co.list instanceof _ListBean", co.list instanceof _ListBean)
		assertTrue("co.fixedSizeList instanceof _ListBean", co.fixedSizeList instanceof _ListBean)
		assertTrue("co.nullList instanceof _ListBean", co.nullList instanceof _ListBean)
		assertTrue("co.realList instanceof _ListBean", co.realList instanceof _ListBean)
		assertTrue("co.realSet instanceof _SetBean", co.realSet instanceof _SetBean)
		assertTrue("co.integerSet instanceof _SetBean", co.integerSet instanceof _SetBean)
		assertTrue("co.map instanceof _MapBean", co.map instanceof _MapBean)

		assertEquals("co.defaultSet.config", CollectionBeanConfig.UNORDERED_SET, co.defaultSet.config)
		assertEquals("co.unorderedSet.config", CollectionBeanConfig.UNORDERED_SET, co.unorderedSet.config)
		assertEquals("co.orderedSet.config", CollectionBeanConfig.ORDERED_SET, co.orderedSet.config)
		assertEquals("co.sortedSet.config", CollectionBeanConfig.SORTED_SET, co.sortedSet.config)
		assertEquals("co.hashSet.config", CollectionBeanConfig.HASH_SET, co.hashSet.config)
		assertEquals("co.list.config", CollectionBeanConfig.LIST, co.list.config)
		assertTrue("co.fixedSizeList.config.list", co.fixedSizeList.config.list)
		assertEquals("co.fixedSizeList.config.fixedSize", 10, co.fixedSizeList.config.fixedSize)
		assertEquals("co.nullList.config", CollectionBeanConfig.NULL_LIST, co.nullList.config)
		assertEquals("co.realList.config", CollectionBeanConfig.LIST, co.realList.config)
		assertEquals("co.realSet.config", CollectionBeanConfig.UNORDERED_SET, co.realSet.config)
		assertEquals("co.integerSet.config", CollectionBeanConfig.UNORDERED_SET, co.integerSet.config)
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
		assertNotNull("co.realList", co.realList)
		assertNotNull("co.realSet", co.realSet)
		assertNotNull("co.integerSet", co.integerSet)
		assertNotNull("co.map", co.map)

		co.defaultSet = null;
		co.unorderedSet = null;
		co.orderedSet = null;
		co.sortedSet = null;
		co.hashSet = null;
		co.list = null;
		co.fixedSizeList = null;
		co.nullList = null;
		co.realList = null;
		co.realSet = null;
		co.integerSet = null;
		co.map = null;

		assertEquals("co.rawDefaultSet", null, co.rawDefaultSet)
		assertEquals("co.rawUnorderedSet", null, co.rawUnorderedSet)
		assertEquals("co.rawOrderedSet", null, co.rawOrderedSet)
		assertEquals("co.rawSortedSet", null, co.rawSortedSet)
		assertEquals("co.rawHashSet", null, co.rawHashSet)
		assertEquals("co.rawList", null, co.rawList)
		assertEquals("co.rawFixedSizeList", null, co.rawFixedSizeList)
		assertEquals("co.rawNullList", null, co.rawNullList)
		assertEquals("co.rawRealList", null, co.rawRealList)
		assertEquals("co.rawRealSet", null, co.rawRealSet)
		assertEquals("co.rawIntegerSet", null, co.rawIntegerSet)
		assertEquals("co.rawMap", null, co.rawMap)
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
		assertNotNull("co.realList", co.realList)
		assertNotNull("co.realSet", co.realSet)
		assertNotNull("co.integerSet", co.integerSet)
		assertNotNull("co.map", co.map)

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
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.realList = co.realList;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.realList = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.realSet = co.realSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.realSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.integerSet = co.integerSet;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.integerSet = <not null>", exception)
		exception = false
		try {
			// Setting a collection to itself is the easiest way to get the
			// right object type, and is also illegal.
			co.map = co.map;
		} catch(Throwable t) {
			exception = true
		}
		assertTrue("co.map = <not null>", exception)

		assertNotNull("co.rawDefaultSet", co.rawDefaultSet)
		assertNotNull("co.rawUnorderedSet", co.rawUnorderedSet)
		assertNotNull("co.rawOrderedSet", co.rawOrderedSet)
		assertNotNull("co.rawSortedSet", co.rawSortedSet)
		assertNotNull("co.rawHashSet", co.rawHashSet)
		assertNotNull("co.rawList", co.rawList)
		assertNotNull("co.rawFixedSizeList", co.rawFixedSizeList)
		assertNotNull("co.rawNullList", co.rawNullList)
		assertNotNull("co.rawRealList", co.rawRealList)
		assertNotNull("co.rawRealSet", co.rawRealSet)
		assertNotNull("co.rawIntegerSet", co.rawIntegerSet)
		assertNotNull("co.rawMap", co.rawMap)
	}
}