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
package test.com.blockwithme.meta

import static org.junit.Assert.*

import org.junit.Test
//import java.util.List
//import com.blockwithme.meta.Hierarchy
//import com.blockwithme.meta.Type
//import com.blockwithme.meta.PropertyType
import org.junit.BeforeClass
//import com.blockwithme.meta.JavaMeta
//import com.blockwithme.meta.beans.Meta
import com.blockwithme.meta.beans.CollectionBean
import java.util.Arrays
import com.blockwithme.meta.JavaMeta

/**
 * Tests the CollectionBean.
 *
 * @author monster
 */
class CollectionBeanTest {
	@BeforeClass
	public static def void classSetup() {
		// Force full init
		TestMeta::TEST.findType(CollectionBean)
	}

    @Test
    public def void testCreation() {
    	val cb = new MyCollectionType
    	assertNotNull("fixedSizeList", cb.fixedSizeList)
    	assertNotNull("list", cb.list)
    	assertNotNull("orderedSet", cb.orderedSet)
    	assertNotNull("sortedSet", cb.sortedSet)
    	assertNotNull("unorderedSet", cb.unorderedSet)

    	assertFalse("fixedSizeList.empty", cb.fixedSizeList.empty)
    	assertTrue("list.empty", cb.list.empty)
    	assertTrue("orderedSet.empty", cb.orderedSet.empty)
    	assertTrue("sortedSet.empty", cb.sortedSet.empty)
    	assertTrue("unorderedSet.empty", cb.unorderedSet.empty)

    	assertEquals("fixedSizeList.size", 10, cb.fixedSizeList.size)
    	assertEquals("list.size", 0, cb.list.size)
    	assertEquals("orderedSet.size", 0, cb.orderedSet.size)
    	assertEquals("sortedSet.size", 0, cb.sortedSet.size)
    	assertEquals("unorderedSet.size", 0, cb.unorderedSet.size)

    	assertEquals("fixedSizeList.valueType", JavaMeta.STRING, cb.fixedSizeList.valueType)
    	assertEquals("list.valueType", JavaMeta.STRING, cb.list.valueType)
    	assertEquals("orderedSet.valueType", JavaMeta.STRING, cb.orderedSet.valueType)
    	assertEquals("sortedSet.valueType", JavaMeta.STRING, cb.sortedSet.valueType)
    	assertEquals("unorderedSet.valueType", JavaMeta.STRING, cb.unorderedSet.valueType)

    	val iter = cb.fixedSizeList.iterator
    	var count = 0
    	while (iter.hasNext) {
    		assertNull("iter.next", iter.next)
    		count = count + 1
    	}
    	assertEquals("count", 10, count)

    	assertEquals("fixedSizeList.toArray.length", 10, cb.fixedSizeList.toArray.length)
    	assertEquals("list.toArray.length", 0, cb.list.toArray.length)
    	assertEquals("orderedSet.toArray.length", 0, cb.orderedSet.toArray.length)
    	assertEquals("sortedSet.toArray.length", 0, cb.sortedSet.toArray.length)
    	assertEquals("unorderedSet.toArray.length", 0, cb.unorderedSet.toArray.length)

    	var cfg = cb.fixedSizeList.config
    	assertEquals("fixedSizeList.config.fixedSize", 10, cfg.fixedSize)
    	assertTrue("fixedSizeList.config.list", cfg.list)
    	assertFalse("fixedSizeList.config.set", cfg.set)
    	assertFalse("fixedSizeList.config.orderedSet", cfg.orderedSet)
    	assertFalse("fixedSizeList.config.sortedSet", cfg.sortedSet)
    	assertFalse("fixedSizeList.config.unorderedSet", cfg.unorderedSet)
    	assertTrue("fixedSizeList.config.nullAllowed", cfg.nullAllowed)
    	assertTrue("fixedSizeList.config.onlyExactType", cfg.onlyExactType)

    	cfg = cb.list.config
    	assertEquals("list.config.fixedSize", -1, cfg.fixedSize)
    	assertTrue("list.config.list", cfg.list)
    	assertFalse("list.config.set", cfg.set)
    	assertFalse("list.config.orderedSet", cfg.orderedSet)
    	assertFalse("list.config.sortedSet", cfg.sortedSet)
    	assertFalse("list.config.unorderedSet", cfg.unorderedSet)
    	assertFalse("list.config.nullAllowed", cfg.nullAllowed)
    	assertFalse("list.config.onlyExactType", cfg.onlyExactType)

    	cfg = cb.orderedSet.config
    	assertEquals("orderedSet.config.fixedSize", -1, cfg.fixedSize)
    	assertFalse("orderedSet.config.list", cfg.list)
    	assertTrue("orderedSet.config.set", cfg.set)
    	assertTrue("orderedSet.config.orderedSet", cfg.orderedSet)
    	assertFalse("orderedSet.config.sortedSet", cfg.sortedSet)
    	assertFalse("orderedSet.config.unorderedSet", cfg.unorderedSet)
    	assertFalse("orderedSet.config.nullAllowed", cfg.nullAllowed)
    	assertFalse("orderedSet.config.onlyExactType", cfg.onlyExactType)

    	cfg = cb.sortedSet.config
    	assertEquals("sortedSet.config.fixedSize", -1, cfg.fixedSize)
    	assertFalse("sortedSet.config.list", cfg.list)
    	assertTrue("sortedSet.config.set", cfg.set)
    	assertFalse("sortedSet.config.orderedSet", cfg.orderedSet)
    	assertTrue("sortedSet.config.sortedSet", cfg.sortedSet)
    	assertFalse("sortedSet.config.unorderedSet", cfg.unorderedSet)
    	assertFalse("sortedSet.config.nullAllowed", cfg.nullAllowed)
    	assertFalse("sortedSet.config.onlyExactType", cfg.onlyExactType)

    	cfg = cb.unorderedSet.config
    	assertEquals("unorderedSet.config.fixedSize", -1, cfg.fixedSize)
    	assertFalse("unorderedSet.config.list", cfg.list)
    	assertTrue("unorderedSet.config.set", cfg.set)
    	assertFalse("unorderedSet.config.orderedSet", cfg.orderedSet)
    	assertFalse("unorderedSet.config.sortedSet", cfg.sortedSet)
    	assertTrue("unorderedSet.config.unorderedSet", cfg.unorderedSet)
    	assertFalse("unorderedSet.config.nullAllowed", cfg.nullAllowed)
    	assertFalse("unorderedSet.config.onlyExactType", cfg.onlyExactType)
	}

    @Test
    public def void testAddOne() {
    	val cb = new MyCollectionType
    	val one = "one"

    	var failed = false
    	try {
    		cb.fixedSizeList.add(one)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: fixedSizeList.add(one)", failed)

    	cb.list.add(one)
    	cb.orderedSet.add(one)
    	cb.sortedSet.add(one)
    	cb.unorderedSet.add(one)

    	assertTrue("fixedSizeList.contains(null)", cb.fixedSizeList.contains(null))
    	assertFalse("list.contains(null)", cb.list.contains(null))
    	assertFalse("orderedSet.contains(null)", cb.orderedSet.contains(null))
    	assertFalse("sortedSet.contains(null)", cb.sortedSet.contains(null))
    	assertFalse("unorderedSet.contains(null)", cb.unorderedSet.contains(null))

    	assertFalse("fixedSizeList.empty", cb.fixedSizeList.empty)
    	assertFalse("list.empty", cb.list.empty)
    	assertFalse("orderedSet.empty", cb.orderedSet.empty)
    	assertFalse("sortedSet.empty", cb.sortedSet.empty)
    	assertFalse("unorderedSet.empty", cb.unorderedSet.empty)

    	assertEquals("fixedSizeList.size", 10, cb.fixedSizeList.size)
    	assertEquals("list.size", 1, cb.list.size)
    	assertEquals("orderedSet.size", 1, cb.orderedSet.size)
    	assertEquals("sortedSet.size", 1, cb.sortedSet.size)
    	assertEquals("unorderedSet.size", 1, cb.unorderedSet.size)

    	assertTrue("fixedSizeList.toArray", Arrays.equals(
    		#[null,null,null,null,null,null,null,null,null,null], cb.fixedSizeList.toArray))
    	assertTrue("list.toArray", Arrays.equals(#[one], cb.list.toArray))
    	assertTrue("orderedSet.toArray", Arrays.equals(#[one], cb.orderedSet.toArray))
    	assertTrue("sortedSet.toArray", Arrays.equals(#[one], cb.sortedSet.toArray))
    	assertTrue("unorderedSet.toArray", Arrays.equals(#[one], cb.unorderedSet.toArray))

    	var iter = cb.fixedSizeList.iterator
    	assertTrue("fixedSizeList.iterator.hasNext", iter.hasNext)
    	assertEquals("fixedSizeList.iterator.next", null, iter.next)
    	assertTrue("fixedSizeList.iterator.hasNext", iter.hasNext)
    	iter = cb.list.iterator
    	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.next", one, iter.next)
    	assertFalse("list.iterator.hasNext", iter.hasNext)
    	iter = cb.orderedSet.iterator
    	assertTrue("orderedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("orderedSet.iterator.next", one, iter.next)
    	assertFalse("orderedSet.iterator.hasNext", iter.hasNext)
    	iter = cb.sortedSet.iterator
    	assertTrue("sortedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("sortedSet.iterator.next", one, iter.next)
    	assertFalse("sortedSet.iterator.hasNext", iter.hasNext)
    	iter = cb.unorderedSet.iterator
    	assertTrue("unorderedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("unorderedSet.iterator.next", one, iter.next)
    	assertFalse("unorderedSet.iterator.hasNext", iter.hasNext)
	}

    @Test
    public def void testAddTwoOne() {
    	val cb = new MyCollectionType
    	val one = "one"
    	val two = "two"

    	cb.list.add(two)
    	cb.list.add(one)
    	cb.orderedSet.add(two)
    	cb.orderedSet.add(one)
    	cb.sortedSet.add(two)
    	cb.sortedSet.add(one)
    	cb.unorderedSet.add(two)
    	cb.unorderedSet.add(one)

    	assertTrue("fixedSizeList.contains(null)", cb.fixedSizeList.contains(null))
    	assertFalse("list.contains(null)", cb.list.contains(null))
    	assertFalse("orderedSet.contains(null)", cb.orderedSet.contains(null))
    	assertFalse("sortedSet.contains(null)", cb.sortedSet.contains(null))
    	assertFalse("unorderedSet.contains(null)", cb.unorderedSet.contains(null))

    	assertFalse("list.empty", cb.list.empty)
    	assertFalse("orderedSet.empty", cb.orderedSet.empty)
    	assertFalse("sortedSet.empty", cb.sortedSet.empty)
    	assertFalse("unorderedSet.empty", cb.unorderedSet.empty)

    	assertEquals("list.size", 2, cb.list.size)
    	assertEquals("orderedSet.size", 2, cb.orderedSet.size)
    	assertEquals("sortedSet.size", 2, cb.sortedSet.size)
    	assertEquals("unorderedSet.size", 2, cb.unorderedSet.size)

    	assertTrue("list.toArray", Arrays.equals(#[two,one], cb.list.toArray))
    	assertTrue("orderedSet.toArray", Arrays.equals(#[two,one], cb.orderedSet.toArray))
    	assertTrue("sortedSet.toArray", Arrays.equals(#[one,two], cb.sortedSet.toArray))
    	assertTrue("unorderedSet.toArray", Arrays.equals(#[one,two], cb.unorderedSet.toArray)
    		|| Arrays.equals(#[two,one], cb.unorderedSet.toArray))

    	assertTrue("list.content", Arrays.equals(#[two,one], cb.list.content))
    	assertTrue("orderedSet.content", Arrays.equals(#[two,one], cb.orderedSet.content))
    	assertTrue("sortedSet.content", Arrays.equals(#[one,two], cb.sortedSet.content))
    	assertTrue("unorderedSet.content", Arrays.equals(#[one,two], cb.unorderedSet.content))

    	var iter = cb.list.iterator
    	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.next", two, iter.next)
    	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.next", one, iter.next)
    	assertFalse("list.iterator.hasNext", iter.hasNext)
    	iter = cb.orderedSet.iterator
    	assertTrue("orderedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("orderedSet.iterator.next", two, iter.next)
    	assertTrue("orderedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("orderedSet.iterator.next", one, iter.next)
    	assertFalse("orderedSet.iterator.hasNext", iter.hasNext)
    	iter = cb.sortedSet.iterator
    	assertTrue("sortedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("sortedSet.iterator.next", one, iter.next)
    	assertTrue("sortedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("sortedSet.iterator.next", two, iter.next)
    	assertFalse("sortedSet.iterator.hasNext", iter.hasNext)
    	iter = cb.unorderedSet.iterator
    	assertTrue("unorderedSet.iterator.hasNext", iter.hasNext)
    	val first = iter.next
    	assertTrue("unorderedSet.iterator.hasNext", iter.hasNext)
    	val second = iter.next
    	assertFalse("unorderedSet.iterator.hasNext", iter.hasNext)
    	assertTrue("unorderedSet.iterator", Arrays.equals(#[one,two], #[first,second])
    		|| Arrays.equals(#[two,one], #[first,second]))

    	assertTrue("list.contains(one)", cb.list.contains(one))
    	assertTrue("list.contains(two)", cb.list.contains(two))
    	assertTrue("orderedSet.contains(one)", cb.orderedSet.contains(one))
    	assertTrue("orderedSet.contains(two)", cb.orderedSet.contains(two))
    	assertTrue("sortedSet.contains(one)", cb.sortedSet.contains(one))
    	assertTrue("sortedSet.contains(two)", cb.sortedSet.contains(two))
    	assertTrue("unorderedSet.contains(one)", cb.unorderedSet.contains(one))
    	assertTrue("unorderedSet.contains(two)", cb.unorderedSet.contains(two))

    	assertTrue("list.containsAll(#[one,two])", cb.list.containsAll(#[one,two]))
    	assertTrue("orderedSet.containsAll(#[one,two])", cb.orderedSet.containsAll(#[one,two]))
    	assertTrue("sortedSet.containsAll(#[one,two])", cb.sortedSet.containsAll(#[one,two]))
    	assertTrue("unorderedSet.containsAll(#[one,two])", cb.unorderedSet.containsAll(#[one,two]))

    	assertFalse("list.retainAll(#[one,two])", cb.list.retainAll(#[one,two]))
    	assertFalse("orderedSet.retainAll(#[one,two])", cb.orderedSet.retainAll(#[one,two]))
    	assertFalse("sortedSet.retainAll(#[one,two])", cb.sortedSet.retainAll(#[one,two]))
    	assertFalse("unorderedSet.retainAll(#[one,two])", cb.unorderedSet.retainAll(#[one,two]))
    	assertEquals("list.size", 2, cb.list.size)
    	assertEquals("orderedSet.size", 2, cb.orderedSet.size)
    	assertEquals("sortedSet.size", 2, cb.sortedSet.size)
    	assertEquals("unorderedSet.size", 2, cb.unorderedSet.size)

    	assertTrue("list.retainAll(#[one,two])", cb.list.removeAll(#[one,two]))
    	assertTrue("orderedSet.retainAll(#[one,two])", cb.orderedSet.removeAll(#[one,two]))
    	assertTrue("sortedSet.retainAll(#[one,two])", cb.sortedSet.removeAll(#[one,two]))
    	assertTrue("unorderedSet.retainAll(#[one,two])", cb.unorderedSet.removeAll(#[one,two]))
    	assertTrue("list.empty", cb.list.empty)
    	assertTrue("orderedSet.empty", cb.orderedSet.empty)
    	assertTrue("sortedSet.empty", cb.sortedSet.empty)
    	assertTrue("unorderedSet.empty", cb.unorderedSet.empty)
	}

    @Test
    public def void testAddTwoOneRemoveTwo() {
    	val cb = new MyCollectionType
    	val one = "one"
    	val two = "two"

    	cb.list.add(two)
    	cb.list.add(one)
    	cb.list.remove(two)
    	cb.orderedSet.add(two)
    	cb.orderedSet.add(one)
    	cb.orderedSet.remove(two)
    	cb.sortedSet.add(two)
    	cb.sortedSet.add(one)
    	cb.sortedSet.remove(two)
    	cb.unorderedSet.add(two)
    	cb.unorderedSet.add(one)
    	cb.unorderedSet.remove(two)

    	assertFalse("list.contains(null)", cb.list.contains(null))
    	assertFalse("orderedSet.contains(null)", cb.orderedSet.contains(null))
    	assertFalse("sortedSet.contains(null)", cb.sortedSet.contains(null))
    	assertFalse("unorderedSet.contains(null)", cb.unorderedSet.contains(null))

    	assertFalse("list.empty", cb.list.empty)
    	assertFalse("orderedSet.empty", cb.orderedSet.empty)
    	assertFalse("sortedSet.empty", cb.sortedSet.empty)
    	assertFalse("unorderedSet.empty", cb.unorderedSet.empty)

    	assertEquals("list.size", 1, cb.list.size)
    	assertEquals("orderedSet.size", 1, cb.orderedSet.size)
    	assertEquals("sortedSet.size", 1, cb.sortedSet.size)
    	assertEquals("unorderedSet.size", 1, cb.unorderedSet.size)

    	assertTrue("list.toArray", Arrays.equals(#[one], cb.list.toArray))
    	assertTrue("orderedSet.toArray", Arrays.equals(#[one], cb.orderedSet.toArray))
    	assertTrue("sortedSet.toArray", Arrays.equals(#[one], cb.sortedSet.toArray))
    	assertTrue("unorderedSet.toArray", Arrays.equals(#[one], cb.unorderedSet.toArray))

    	var iter = cb.list.iterator
    	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.next", one, iter.next)
    	assertFalse("list.iterator.hasNext", iter.hasNext)
    	iter = cb.orderedSet.iterator
    	assertTrue("orderedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("orderedSet.iterator.next", one, iter.next)
    	assertFalse("orderedSet.iterator.hasNext", iter.hasNext)
    	iter = cb.sortedSet.iterator
    	assertTrue("sortedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("sortedSet.iterator.next", one, iter.next)
    	assertFalse("sortedSet.iterator.hasNext", iter.hasNext)
    	iter = cb.unorderedSet.iterator
    	assertTrue("unorderedSet.iterator.hasNext", iter.hasNext)
    	assertEquals("unorderedSet.iterator.next", one, iter.next)
    	assertFalse("unorderedSet.iterator.hasNext", iter.hasNext)
	}

    @Test
    public def void testAddTwoOneClear() {
    	val cb = new MyCollectionType
    	val one = "one"
    	val two = "two"

    	cb.list.add(two)
    	cb.list.add(one)
    	cb.list.clear()
    	cb.orderedSet.add(two)
    	cb.orderedSet.add(one)
    	cb.orderedSet.clear()
    	cb.sortedSet.add(two)
    	cb.sortedSet.add(one)
    	cb.sortedSet.clear()
    	cb.unorderedSet.add(two)
    	cb.unorderedSet.add(one)
    	cb.unorderedSet.clear()

    	assertTrue("list.empty", cb.list.empty)
    	assertTrue("orderedSet.empty", cb.orderedSet.empty)
    	assertTrue("sortedSet.empty", cb.sortedSet.empty)
    	assertTrue("unorderedSet.empty", cb.unorderedSet.empty)

    	assertEquals("list.size", 0, cb.list.size)
    	assertEquals("orderedSet.size", 0, cb.orderedSet.size)
    	assertEquals("sortedSet.size", 0, cb.sortedSet.size)
    	assertEquals("unorderedSet.size", 0, cb.unorderedSet.size)
	}

    @Test
    public def void testAddAllTwoOne() {
    	val cb = new MyCollectionType
    	val one = "one"
    	val two = "two"

    	cb.list.addAll(#[two,one])
    	cb.orderedSet.addAll(#[two,one])
    	cb.sortedSet.addAll(#[two,one])
    	cb.unorderedSet.addAll(#[two,one])

    	assertTrue("list.toArray", Arrays.equals(#[two,one], cb.list.toArray(<CharSequence>newArrayOfSize(2))))
    	assertTrue("orderedSet.toArray", Arrays.equals(#[two,one], cb.orderedSet.toArray(<CharSequence>newArrayOfSize(2))))
    	assertTrue("sortedSet.toArray", Arrays.equals(#[one,two], cb.sortedSet.toArray(<CharSequence>newArrayOfSize(2))))
    	assertTrue("unorderedSet.toArray", Arrays.equals(#[one,two], cb.unorderedSet.toArray(<CharSequence>newArrayOfSize(2)))
    		|| Arrays.equals(#[two,one], cb.unorderedSet.toArray(<CharSequence>newArrayOfSize(2))))
	}

    @Test
    public def void testAddNull() {
    	val cb = new MyCollectionType

    	var failed = false
    	try {
	    	cb.list.add(null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: list.add(null)", failed)
    	failed = false
    	try {
	    	cb.orderedSet.add(null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: orderedSet.add(null)", failed)
    	failed = false
    	try {
	    	cb.sortedSet.add(null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: sortedSet.add(null)", failed)
    	failed = false
    	try {
	    	cb.unorderedSet.add(null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: unorderedSet.add(null)", failed)
	}

    @Test
    public def void testIndice() {
    	val cb = new MyCollectionType
    	val one = "one"
    	val two = "two"
    	val three = "three"

    	assertEquals("fixedSizeList.set(0,one)", null, cb.fixedSizeList.set(0,one))
    	assertEquals("fixedSizeList.set(1,two)", null, cb.fixedSizeList.set(1,two))
    	cb.list.addAll(#[three,three])
    	assertEquals("list.set(0,one)", three, cb.list.set(0,one))
    	assertEquals("list.set(1,two)", three, cb.list.set(1,two))

    	assertTrue("fixedSizeList.toArray",
    		Arrays.equals(#[one,two,null,null,null,null,null,null,null,null], cb.fixedSizeList.toArray))
    	assertTrue("list.toArray", Arrays.equals(#[one,two], cb.list.toArray))

    	assertEquals("fixedSizeList.get(0)", one, cb.fixedSizeList.get(0))
    	assertEquals("fixedSizeList.get(1)", two, cb.fixedSizeList.get(1))
    	assertEquals("list.get(0)", one, cb.list.get(0))
    	assertEquals("list.get(1)", two, cb.list.get(1))

     	assertEquals("fixedSizeList.indexOf(one)", 0, cb.fixedSizeList.indexOf(one))
     	assertEquals("fixedSizeList.indexOf(two)", 1, cb.fixedSizeList.indexOf(two))
     	assertEquals("fixedSizeList.indexOf(two)", 2, cb.fixedSizeList.indexOf(null))
     	assertEquals("fixedSizeList.indexOf(three)", -1, cb.fixedSizeList.indexOf(three))
     	assertEquals("list.indexOf(one)", 0, cb.list.indexOf(one))
     	assertEquals("list.indexOf(two)", 1, cb.list.indexOf(two))
     	assertEquals("list.indexOf(two)", -1, cb.list.indexOf(null))
     	assertEquals("list.indexOf(three)", -1, cb.list.indexOf(three))

     	assertEquals("fixedSizeList.lastIndexOf(one)", 0, cb.fixedSizeList.lastIndexOf(one))
     	assertEquals("fixedSizeList.lastIndexOf(two)", 1, cb.fixedSizeList.lastIndexOf(two))
     	assertEquals("fixedSizeList.lastIndexOf(two)", 9, cb.fixedSizeList.lastIndexOf(null))
     	assertEquals("fixedSizeList.lastIndexOf(three)", -1, cb.fixedSizeList.lastIndexOf(three))
     	assertEquals("list.lastIndexOf(one)", 0, cb.list.lastIndexOf(one))
     	assertEquals("list.lastIndexOf(two)", 1, cb.list.lastIndexOf(two))
     	assertEquals("list.lastIndexOf(two)", -1, cb.list.lastIndexOf(null))
     	assertEquals("list.lastIndexOf(three)", -1, cb.list.lastIndexOf(three))

    	assertEquals("fixedSizeList.remove(0)#1", one, cb.fixedSizeList.remove(0))
    	assertEquals("fixedSizeList.remove(0)#2", null, cb.fixedSizeList.remove(0))
    	assertEquals("fixedSizeList.remove(1)", two, cb.fixedSizeList.remove(1))
    	assertEquals("fixedSizeList.get(0)", null, cb.fixedSizeList.get(0))
    	assertEquals("fixedSizeList.get(1)", null, cb.fixedSizeList.get(1))
    	assertEquals("list.remove(0)#1", one, cb.list.remove(0))
    	assertEquals("list.remove(0)#2", two, cb.list.remove(0))
     	assertEquals("fixedSizeList.size", 10, cb.fixedSizeList.size)
     	assertEquals("list.size", 0, cb.list.size)

    	var failed = false
    	try {
    		cb.fixedSizeList.add(0,three)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: fixedSizeList.add(0,three)", failed)
    	cb.list.add(two)
    	assertTrue("list.toArray", Arrays.equals(#[two], cb.list.toArray))
    	cb.list.add(0,one)
    	assertTrue("list.toArray", Arrays.equals(#[one,two], cb.list.toArray))
    	cb.list.add(2,three)
    	assertTrue("list.toArray", Arrays.equals(#[one,two,three], cb.list.toArray))


    	failed = false
    	try {
    		cb.fixedSizeList.addAll(0,#[three])
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: fixedSizeList.addAll(0,#[three])", failed)
    	cb.list.clear()
    	cb.list.add(three)
    	assertTrue("list.addAll(0,#[one,two])", cb.list.addAll(0,#[one,two]))
    	assertTrue("list.toArray", Arrays.equals(#[one,two,three], cb.list.toArray))
    	assertTrue("list.addAll(0,#[one,two])", cb.list.addAll(1,#[three]))
    	assertTrue("list.toArray", Arrays.equals(#[one,three,two,three], cb.list.toArray))
     	assertEquals("list.indexOf(three)", 1, cb.list.indexOf(three))
     	assertEquals("list.lastIndexOf(three)", 3, cb.list.lastIndexOf(three))
	}

    @Test
    public def void testSetNull() {
    	val cb = new MyCollectionType
    	val one = "one"
    	cb.fixedSizeList.set(0,one)
    	cb.list.add(one)
    	cb.orderedSet.add(one)
    	cb.sortedSet.add(one)
    	cb.unorderedSet.add(one)

    	var failed = false
    	try {
	    	cb.fixedSizeList.set(0,null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertFalse("failed: fixedSizeList.set(0,null)", failed)
    	failed = false
    	try {
	    	cb.list.set(0,null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: list.set(0,null)", failed)
    	failed = false
    	try {
	    	cb.orderedSet.set(0,null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: orderedSet.set(0,null)", failed)
    	failed = false
    	try {
	    	cb.sortedSet.set(0,null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: sortedSet.set(0,null)", failed)
    	failed = false
    	try {
	    	cb.unorderedSet.set(0,null)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: unorderedSet.set(0,null)", failed)
	}

    @Test
    public def void testIterator() {
    	val cb = new MyCollectionType
     	val one = "one"
    	val two = "two"
    	val three = "three"
    	cb.fixedSizeList.set(0,one)
    	cb.fixedSizeList.set(1,two)
    	cb.fixedSizeList.set(2,three)
    	cb.list.addAll(#[one,two,three])

    	var iter = cb.fixedSizeList.listIterator
     	assertTrue("fixedSizeList.iterator.hasNext", iter.hasNext)
    	assertEquals("fixedSizeList.iterator.nextIndex", 0, iter.nextIndex)
    	assertEquals("fixedSizeList.iterator.next", one, iter.next)
     	assertTrue("fixedSizeList.iterator.hasNext", iter.hasNext)
    	assertEquals("fixedSizeList.iterator.nextIndex", 1, iter.nextIndex)
    	assertEquals("fixedSizeList.iterator.next", two, iter.next)
     	assertTrue("fixedSizeList.iterator.hasNext", iter.hasNext)
    	assertEquals("fixedSizeList.iterator.nextIndex", 2, iter.nextIndex)
    	assertEquals("fixedSizeList.iterator.next", three, iter.next)
     	assertTrue("fixedSizeList.iterator.hasNext", iter.hasNext)
    	assertEquals("fixedSizeList.iterator.nextIndex", 3, iter.nextIndex)
    	assertEquals("fixedSizeList.iterator.next", null, iter.next)
     	assertTrue("fixedSizeList.iterator.hasNext", iter.hasPrevious)
    	assertEquals("fixedSizeList.iterator.previousIndex", 3, iter.previousIndex)
    	assertEquals("fixedSizeList.iterator.previous", null, iter.previous)
     	assertTrue("fixedSizeList.iterator.hasPrevious", iter.hasPrevious)
    	assertEquals("fixedSizeList.iterator.previousIndex", 2, iter.previousIndex)
    	assertEquals("fixedSizeList.iterator.previous", three, iter.previous)
     	assertTrue("fixedSizeList.iterator.hasPrevious", iter.hasPrevious)
    	assertEquals("fixedSizeList.iterator.previousIndex", 1, iter.previousIndex)
    	assertEquals("fixedSizeList.iterator.previous", two, iter.previous)
     	assertTrue("fixedSizeList.iterator.hasPrevious", iter.hasPrevious)
    	assertEquals("fixedSizeList.iterator.previousIndex", 0, iter.previousIndex)
    	assertEquals("fixedSizeList.iterator.previous", one, iter.previous)
     	assertFalse("fixedSizeList.iterator.hasPrevious", iter.hasPrevious)

    	iter = cb.list.listIterator
     	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.nextIndex", 0, iter.nextIndex)
    	assertEquals("list.iterator.next", one, iter.next)
     	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.nextIndex", 1, iter.nextIndex)
    	assertEquals("list.iterator.next", two, iter.next)
     	assertTrue("list.iterator.hasNext", iter.hasNext)
    	assertEquals("list.iterator.nextIndex", 2, iter.nextIndex)
    	assertEquals("list.iterator.next", three, iter.next)
     	assertFalse("list.iterator.hasNext", iter.hasNext)
     	assertTrue("list.iterator.hasPrevious", iter.hasPrevious)
    	assertEquals("list.iterator.previousIndex", 2, iter.previousIndex)
    	assertEquals("fixedSizeList.iterator.previous", three, iter.previous)
     	assertTrue("list.iterator.hasPrevious", iter.hasPrevious)
    	assertEquals("list.iterator.previousIndex", 1, iter.previousIndex)
    	assertEquals("list.iterator.previous", two, iter.previous)
     	assertTrue("list.iterator.hasPrevious", iter.hasPrevious)
    	assertEquals("list.iterator.previousIndex", 0, iter.previousIndex)
    	assertEquals("list.iterator.previous", one, iter.previous)
     	assertFalse("list.iterator.hasPrevious", iter.hasPrevious)

     	iter = cb.fixedSizeList.listIterator
     	iter.next
     	iter.remove
     	iter.next
     	iter.remove
     	iter.next
     	iter.remove
    	iter = cb.list.listIterator
     	iter.next
     	iter.remove
     	iter.next
     	iter.remove
     	iter.next
     	iter.remove
    	assertTrue("fixedSizeList.toArray", Arrays.equals(
    		#[null,null,null,null,null,null,null,null,null,null], cb.fixedSizeList.toArray))
    	assertTrue("list.empty", cb.list.empty)

    	cb.fixedSizeList.set(0,one)
    	cb.list.add(one)
     	iter = cb.fixedSizeList.listIterator
     	iter.next
     	iter.next
     	iter.set(two)
    	assertTrue("fixedSizeList.toArray", Arrays.equals(
    		#[one,two,null,null,null,null,null,null,null,null], cb.fixedSizeList.toArray))
     	iter = cb.list.listIterator
     	iter.next
     	iter.add(two)
    	assertTrue("list.toArray", Arrays.equals(#[one,two], cb.list.toArray))
	}

    @Test
    public def void testCopySnapshotWrapper() {
    	val cb = new MyCollectionType
     	val one = "one"
    	val two = "two"
    	val three = "three"
    	cb.list.addAll(#[one,two,three])

    	var copy = cb.list.copy
     	assertTrue("list.content == list.copy.content", Arrays.equals(cb.list.content, copy.content))
     	assertEquals("list == list.copy", cb.list, copy)
     	assertFalse("list.copy.immutable", copy.immutable)

     	var snap = cb.list.snapshot
     	assertTrue("list.content == list.snapshot.content", Arrays.equals(cb.list.content, snap.content))
     	assertTrue("list.snapshot.immutable", snap.immutable)

     	var wrap = cb.list.wrapper
     	assertTrue("list.content == list.wrapper.content", Arrays.equals(cb.list.content, wrap.content))
     	assertFalse("list.wrap.immutable", wrap.immutable)

		assertEquals("copy.remove(1)", two, copy.remove(1))
     	assertTrue("list.content == [one,two,three]", Arrays.equals(cb.list.content, #[one,two,three]))
     	assertTrue("list.copy.content == [one,three]", Arrays.equals(copy.content, #[one,three]))
     	assertEquals("list.size", 3, cb.list.size)
     	assertEquals("list.copy.size", 2, copy.size)

    	var failed = false
    	try {
	    	snap.remove(1)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: snap.remove(1)", failed)
     	assertEquals("list.size", 3, cb.list.size)
     	assertEquals("list.snap.size", 3, snap.size)

		assertEquals("wrap.remove(1)", two, wrap.remove(1))
     	assertTrue("list.content == [one,two,three]", Arrays.equals(cb.list.content, #[one,two,three]))
     	assertTrue("list.wrap.content == [one,three]", Arrays.equals(wrap.content, #[one,three]))
     	assertEquals("list.size", 3, cb.list.size)
     	assertEquals("list.wrap.size", 2, wrap.size)

     	cb.list.remove(1)
     	copy = cb.list.copy
     	snap = cb.list.snapshot
     	wrap = cb.list.wrapper

		copy.add(1,two)
     	assertTrue("list.content == [one,three]", Arrays.equals(cb.list.content, #[one,three]))
     	assertTrue("list.copy.content == [one,two,three]", Arrays.equals(copy.content, #[one,two,three]))
     	assertEquals("list.size", 2, cb.list.size)
     	assertEquals("list.copy.size", 3, copy.size)

    	failed = false
    	try {
	    	snap.add(1,two)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: snap.add(1,two)", failed)
     	assertEquals("list.size", 2, cb.list.size)
     	assertEquals("list.snap.size", 2, snap.size)

		wrap.add(1,two)
     	assertTrue("list.content == [one,three]", Arrays.equals(cb.list.content, #[one,three]))
     	assertTrue("list.wrap.content == [one,two,three]", Arrays.equals(wrap.content, #[one,two,three]))
     	assertEquals("list.size", 2, cb.list.size)
     	assertEquals("list.wrap.size", 3, wrap.size)
	}
}