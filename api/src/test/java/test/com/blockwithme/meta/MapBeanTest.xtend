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
import org.junit.BeforeClass
import org.junit.Test
import com.blockwithme.meta.beans.MapBean
import com.blockwithme.meta.JavaMeta
import java.util.Arrays
import java.util.Map
import java.util.HashMap
import com.blockwithme.meta.beans.BeanPath
import java.util.ArrayList

/**
 * @author monster
 *
 */
class MapBeanTest extends BaseTst {
	@BeforeClass
	public static def void classSetup() {
		// Force full init
		TestMeta::TEST.findType(MapBean)
	}

    @Test
    public def void testCreation() {
    	val mmt = new MyMapType
    	assertNotNull("map", mmt.map)
    	assertEquals("map.keyType", JavaMeta.STRING, mmt.map.keyType)
    	assertEquals("map.valueType", JavaMeta.LONG, mmt.map.valueType)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.empty", mmt.map.empty)
    	assertTrue("map.keySet.empty", mmt.map.keySet.empty)
    	assertTrue("map.values.empty", mmt.map.values.empty)
    	assertTrue("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 0, mmt.map.size)
    	assertEquals("map.keySet.size", 0, mmt.map.keySet.size)
    	assertEquals("map.values.size", 0, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 0, mmt.map.entrySet.size)
    	assertFalse("map.keySet.iterator.hasNext", mmt.map.keySet.iterator.hasNext)
    	assertFalse("map.values.iterator.hasNext", mmt.map.values.iterator.hasNext)
    	assertFalse("map.entrySet.iterator.hasNext", mmt.map.entrySet.iterator.hasNext)
    	assertEquals("map.keySet.toArray.length", 0, mmt.map.keySet.toArray.length)
    	assertEquals("map.values.toArray.length", 0, mmt.map.values.toArray.length)
    	assertEquals("map.entrySet.toArray.length", 0, mmt.map.entrySet.toArray.length)
	}

    @Test
    public def void testPutOne() {
    	val mmt = new MyMapType
    	val one = "one"

    	mmt.map.put(one, 1L)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.containsKey(one)", mmt.map.containsKey(one))
    	assertTrue("map.containsValue(1L)", mmt.map.containsValue(1L))
    	assertFalse("map.empty", mmt.map.empty)
    	assertFalse("map.keySet.empty", mmt.map.keySet.empty)
    	assertFalse("map.values.empty", mmt.map.values.empty)
    	assertFalse("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 1, mmt.map.size)
    	assertEquals("map.keySet.size", 1, mmt.map.keySet.size)
    	assertEquals("map.values.size", 1, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 1, mmt.map.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[one], mmt.map.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[1L], mmt.map.values.toArray))
    	val esa = mmt.map.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", esa)
    	assertEquals("map.entrySet.toArray.length", 1, esa.length)
    	val esa0 = esa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", esa0)
    	assertEquals("map.entrySet.toArray[0].key", one, esa0.key)
    	assertEquals("map.entrySet.toArray[0].value", 1L, esa0.value)

    	val iterK = mmt.map.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)

    	val iterV = mmt.map.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 1L, iterV.next)
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)

    	val iterE = mmt.map.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", 1L, e.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)
	}

    @Test
    public def void testPutOneTwo() {
    	val mmt = new MyMapType
    	val one = "one"
    	val two = "two"

    	mmt.map.put(one, 1L)
    	mmt.map.put(two, 2L)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.containsKey(one)", mmt.map.containsKey(one))
    	assertTrue("map.containsValue(1L)", mmt.map.containsValue(1L))
    	assertTrue("map.containsKey(two)", mmt.map.containsKey(two))
    	assertTrue("map.containsValue(2L)", mmt.map.containsValue(2L))
    	assertFalse("map.empty", mmt.map.empty)
    	assertFalse("map.keySet.empty", mmt.map.keySet.empty)
    	assertFalse("map.values.empty", mmt.map.values.empty)
    	assertFalse("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 2, mmt.map.size)
    	assertEquals("map.keySet.size", 2, mmt.map.keySet.size)
    	assertEquals("map.values.size", 2, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 2, mmt.map.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[one,two], mmt.map.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[1L,2L], mmt.map.values.toArray))
    	val esa = mmt.map.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", esa)
    	assertEquals("map.entrySet.toArray.length", 2, esa.length)
    	val esa0 = esa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", esa0)
    	assertEquals("map.entrySet.toArray[0].key", one, esa0.key)
    	assertEquals("map.entrySet.toArray[0].value", 1L, esa0.value)
    	val esa1 = esa.get(1)
    	assertNotNull("map.entrySet.toArray[1]", esa1)
    	assertEquals("map.entrySet.toArray[1].key", two, esa1.key)
    	assertEquals("map.entrySet.toArray[1].value", 2L, esa1.value)

    	val iterK = mmt.map.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", two, iterK.next)
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)

    	val iterV = mmt.map.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 1L, iterV.next)
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 2L, iterV.next)
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)

    	val iterE = mmt.map.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", 1L, e.value)
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e2 = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e2)
    	assertEquals("map.entrySet.iterator.next.key", two, e2.key)
    	assertEquals("map.entrySet.iterator.next.value", 2L, e2.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)
	}

    @Test
    public def void testPutTwoOneRemoveTwo() {
    	val mmt = new MyMapType
    	val one = "one"
    	val two = "two"

    	mmt.map.put(two, 2L)
    	mmt.map.put(one, 1L)
    	mmt.map.remove(two)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.containsKey(one)", mmt.map.containsKey(one))
    	assertTrue("map.containsValue(1L)", mmt.map.containsValue(1L))
    	assertFalse("map.empty", mmt.map.empty)
    	assertFalse("map.keySet.empty", mmt.map.keySet.empty)
    	assertFalse("map.values.empty", mmt.map.values.empty)
    	assertFalse("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 1, mmt.map.size)
    	assertEquals("map.keySet.size", 1, mmt.map.keySet.size)
    	assertEquals("map.values.size", 1, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 1, mmt.map.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[one], mmt.map.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[1L], mmt.map.values.toArray))
    	val esa = mmt.map.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", esa)
    	assertEquals("map.entrySet.toArray.length", 1, esa.length)
    	val esa0 = esa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", esa0)
    	assertEquals("map.entrySet.toArray[0].key", one, esa0.key)
    	assertEquals("map.entrySet.toArray[0].value", 1L, esa0.value)

    	val iterK = mmt.map.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)

    	val iterV = mmt.map.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 1L, iterV.next)
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)

    	val iterE = mmt.map.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", 1L, e.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)
	}

    @Test
    public def void testPutTwoOneClear() {
    	val mmt = new MyMapType
    	val one = "one"
    	val two = "two"

    	mmt.map.put(two, 2L)
    	mmt.map.put(one, 1L)
    	mmt.map.clear

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.empty", mmt.map.empty)
    	assertTrue("map.keySet.empty", mmt.map.keySet.empty)
    	assertTrue("map.values.empty", mmt.map.values.empty)
    	assertTrue("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 0, mmt.map.size)
    	assertEquals("map.keySet.size", 0, mmt.map.keySet.size)
    	assertEquals("map.values.size", 0, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 0, mmt.map.entrySet.size)
    	assertFalse("map.keySet.iterator.hasNext", mmt.map.keySet.iterator.hasNext)
    	assertFalse("map.values.iterator.hasNext", mmt.map.values.iterator.hasNext)
    	assertFalse("map.entrySet.iterator.hasNext", mmt.map.entrySet.iterator.hasNext)
    	assertEquals("map.keySet.toArray.length", 0, mmt.map.keySet.toArray.length)
    	assertEquals("map.values.toArray.length", 0, mmt.map.values.toArray.length)
    	assertEquals("map.entrySet.toArray.length", 0, mmt.map.entrySet.toArray.length)
	}

    @Test
    public def void testPutAllTwoOne() {
    	val mmt = new MyMapType
    	val one = "one"
    	val two = "two"

		val map = new HashMap<String,Long>
    	map.put(two, 2L)
    	map.put(one, 1L)

    	mmt.map.putAll(map)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.containsKey(one)", mmt.map.containsKey(one))
    	assertTrue("map.containsValue(1L)", mmt.map.containsValue(1L))
    	assertTrue("map.containsKey(two)", mmt.map.containsKey(two))
    	assertTrue("map.containsValue(2L)", mmt.map.containsValue(2L))
    	assertFalse("map.empty", mmt.map.empty)
    	assertFalse("map.keySet.empty", mmt.map.keySet.empty)
    	assertFalse("map.values.empty", mmt.map.values.empty)
    	assertFalse("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 2, mmt.map.size)
    	assertEquals("map.keySet.size", 2, mmt.map.keySet.size)
    	assertEquals("map.values.size", 2, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 2, mmt.map.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[one,two], mmt.map.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[1L,2L], mmt.map.values.toArray))
    	val esa = mmt.map.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", esa)
    	assertEquals("map.entrySet.toArray.length", 2, esa.length)
    	val esa0 = esa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", esa0)
    	assertEquals("map.entrySet.toArray[0].key", one, esa0.key)
    	assertEquals("map.entrySet.toArray[0].value", 1L, esa0.value)
    	val esa1 = esa.get(1)
    	assertNotNull("map.entrySet.toArray[1]", esa1)
    	assertEquals("map.entrySet.toArray[1].key", two, esa1.key)
    	assertEquals("map.entrySet.toArray[1].value", 2L, esa1.value)

    	val iterK = mmt.map.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", two, iterK.next)
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)

    	val iterV = mmt.map.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 1L, iterV.next)
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 2L, iterV.next)
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)

    	val iterE = mmt.map.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", 1L, e.value)
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e2 = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e2)
    	assertEquals("map.entrySet.iterator.next.key", two, e2.key)
    	assertEquals("map.entrySet.iterator.next.value", 2L, e2.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)
	}

    @Test
    public def void testPutNullKey() {
    	val mmt = new MyMapType
    	var failed = false
    	try {
	    	mmt.map.put(null, 1L)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: map.put(null,?)", failed)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertFalse("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.empty", mmt.map.empty)
    	assertTrue("map.keySet.empty", mmt.map.keySet.empty)
    	assertTrue("map.values.empty", mmt.map.values.empty)
    	assertTrue("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 0, mmt.map.size)
    	assertEquals("map.keySet.size", 0, mmt.map.keySet.size)
    	assertEquals("map.values.size", 0, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 0, mmt.map.entrySet.size)
    	assertFalse("map.keySet.iterator.hasNext", mmt.map.keySet.iterator.hasNext)
    	assertFalse("map.values.iterator.hasNext", mmt.map.values.iterator.hasNext)
    	assertFalse("map.entrySet.iterator.hasNext", mmt.map.entrySet.iterator.hasNext)
    	assertEquals("map.keySet.toArray.length", 0, mmt.map.keySet.toArray.length)
    	assertEquals("map.values.toArray.length", 0, mmt.map.values.toArray.length)
    	assertEquals("map.entrySet.toArray.length", 0, mmt.map.entrySet.toArray.length)
	}

    @Test
    public def void testPutNullValue() {
    	val mmt = new MyMapType
    	val one = "one"

    	mmt.map.put(one, null)

    	assertFalse("map.containsKey(null)", mmt.map.containsKey(null))
    	assertTrue("map.containsValue(null)", mmt.map.containsValue(null))
    	assertTrue("map.containsKey(one)", mmt.map.containsKey(one))
    	assertFalse("map.empty", mmt.map.empty)
    	assertFalse("map.keySet.empty", mmt.map.keySet.empty)
    	assertFalse("map.values.empty", mmt.map.values.empty)
    	assertFalse("map.entrySet.empty", mmt.map.entrySet.empty)
    	assertEquals("map.size", 1, mmt.map.size)
    	assertEquals("map.keySet.size", 1, mmt.map.keySet.size)
    	assertEquals("map.values.size", 1, mmt.map.values.size)
    	assertEquals("map.entrySet.size", 1, mmt.map.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[one], mmt.map.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[null], mmt.map.values.toArray))
    	val esa = mmt.map.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", esa)
    	assertEquals("map.entrySet.toArray.length", 1, esa.length)
    	val esa0 = esa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", esa0)
    	assertEquals("map.entrySet.toArray[0].key", one, esa0.key)
    	assertEquals("map.entrySet.toArray[0].value", null, esa0.value)

    	val iterK = mmt.map.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)

    	val iterV = mmt.map.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", null, iterV.next)
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)

    	val iterE = mmt.map.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", null, e.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)
	}

    @Test
    public def void testIterator() {
    	val mmt = new MyMapType
    	val one = "one"
    	val two = "two"
    	val three = "three"

    	mmt.map.put(one, 1L)
    	mmt.map.put(two, 2L)
    	mmt.map.put(three, 3L)
    	val iterK = mmt.map.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	iterK.remove
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", two, iterK.next)
    	iterK.remove
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", three, iterK.next)
    	iterK.remove
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertTrue("map.empty", mmt.map.empty)
    	assertTrue("map.keySet.empty", mmt.map.keySet.empty)
    	assertTrue("map.values.empty", mmt.map.values.empty)
    	assertTrue("map.entrySet.empty", mmt.map.entrySet.empty)

    	mmt.map.put(one, 1L)
    	mmt.map.put(two, 2L)
    	mmt.map.put(three, 3L)
    	val iterV = mmt.map.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 1L, iterV.next)
    	iterV.remove
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 2L, iterV.next)
    	iterV.remove
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 3L, iterV.next)
    	iterV.remove
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)
    	assertTrue("map.empty", mmt.map.empty)
    	assertTrue("map.keySet.empty", mmt.map.keySet.empty)
    	assertTrue("map.values.empty", mmt.map.values.empty)
    	assertTrue("map.entrySet.empty", mmt.map.entrySet.empty)

    	mmt.map.put(one, 1L)
    	mmt.map.put(two, 2L)
    	mmt.map.put(three, 3L)
    	val iterE = mmt.map.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	iterE.remove
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", 1L, e.value)
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e2 = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e2)
    	iterE.remove
    	assertEquals("map.entrySet.iterator.next.key", two, e2.key)
    	assertEquals("map.entrySet.iterator.next.value", 2L, e2.value)
    	val e3 = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e3)
    	iterE.remove
    	assertEquals("map.entrySet.iterator.next.key", three, e3.key)
    	assertEquals("map.entrySet.iterator.next.value", 3L, e3.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)
    	assertTrue("map.empty", mmt.map.empty)
    	assertTrue("map.keySet.empty", mmt.map.keySet.empty)
    	assertTrue("map.values.empty", mmt.map.values.empty)
    	assertTrue("map.entrySet.empty", mmt.map.entrySet.empty)
	}

	@Test
	public def void testLargeCapacity() {
    	val mmt = new MyMapType
     	val one = "one"
    	val two = "two"
    	val three = "three"
     	val four = "four"
    	val five = "five"
    	val six = "six"
     	val seven = "seven"
    	val eight = "eight"
    	val nine = "nine"
    	mmt.map.put(one, 1L)
    	mmt.map.put(two, 2L)
    	mmt.map.put(three, 3L)
    	mmt.map.put(four, 4L)
    	mmt.map.put(five, 5L)
    	mmt.map.put(six, 6L)
    	mmt.map.put(seven, 7L)
    	mmt.map.put(eight, 8L)
    	mmt.map.put(nine, 9L)
     	assertEquals("mmt.map", 9, mmt.map.size)
	}

    @Test
    public def void testCopySnapshot() {
    	val orig = new MyMapType
    	assertFalse("snapshot.immutable", orig.map.immutable)
    	val one = "one"
    	val two = "two"
    	val three = "three"

    	orig.map.put(two, 2L)

    	val copy = orig.map.copy()
    	assertFalse("snapshot.immutable", copy.immutable)
    	copy.put(one, 1L)
    	orig.map.put(three, 3L)

    	assertFalse("map.containsKey(null)", copy.containsKey(null))
    	assertFalse("map.containsValue(null)", copy.containsValue(null))
    	assertTrue("map.containsKey(one)", copy.containsKey(one))
    	assertTrue("map.containsValue(1L)", copy.containsValue(1L))
    	assertTrue("map.containsKey(two)", copy.containsKey(two))
    	assertTrue("map.containsValue(2L)", copy.containsValue(2L))
    	assertFalse("map.empty", copy.empty)
    	assertFalse("map.keySet.empty", copy.keySet.empty)
    	assertFalse("map.values.empty", copy.values.empty)
    	assertFalse("map.entrySet.empty", copy.entrySet.empty)
    	assertEquals("map.size", 2, copy.size)
    	assertEquals("map.keySet.size", 2, copy.keySet.size)
    	assertEquals("map.values.size", 2, copy.values.size)
    	assertEquals("map.entrySet.size", 2, copy.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[one,two], copy.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[1L,2L], copy.values.toArray))
    	val esa = copy.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", esa)
    	assertEquals("map.entrySet.toArray.length", 2, esa.length)
    	val esa0 = esa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", esa0)
    	assertEquals("map.entrySet.toArray[0].key", one, esa0.key)
    	assertEquals("map.entrySet.toArray[0].value", 1L, esa0.value)
    	val esa1 = esa.get(1)
    	assertNotNull("map.entrySet.toArray[1]", esa1)
    	assertEquals("map.entrySet.toArray[1].key", two, esa1.key)
    	assertEquals("map.entrySet.toArray[1].value", 2L, esa1.value)

    	val iterK = copy.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", one, iterK.next)
    	assertTrue("map.keySet.iterator.hasNext", iterK.hasNext)
    	assertEquals("map.keySet.iterator.next", two, iterK.next)
    	assertFalse("map.keySet.iterator.hasNext", iterK.hasNext)

    	val iterV = copy.values.iterator
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 1L, iterV.next)
    	assertTrue("map.values.iterator.hasNext", iterV.hasNext)
    	assertEquals("map.values.iterator.next", 2L, iterV.next)
    	assertFalse("map.values.iterator.hasNext", iterV.hasNext)

    	val iterE = copy.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e)
    	assertEquals("map.entrySet.iterator.next.key", one, e.key)
    	assertEquals("map.entrySet.iterator.next.value", 1L, e.value)
    	assertTrue("map.entrySet.iterator.hasNext", iterE.hasNext)
    	val e2 = iterE.next
    	assertNotNull("map.entrySet.iterator.next", e2)
    	assertEquals("map.entrySet.iterator.next.key", two, e2.key)
    	assertEquals("map.entrySet.iterator.next.value", 2L, e2.value)
    	assertFalse("map.entrySet.iterator.hasNext", iterE.hasNext)

		orig.map.remove(three)
    	val snapshot = orig.map.snapshot
    	assertTrue("snapshot.immutable", snapshot.immutable)
    	var failed = false
    	try {
	    	snapshot.put(one, 1L)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: snapshot.put(one, 1L)", failed)
    	failed = false
    	try {
	    	snapshot.remove(two)
    	} catch(Throwable t) {
    		failed = true
    	}
    	assertTrue("failed: remove(two)", failed)

    	assertFalse("map.containsKey(null)", snapshot.containsKey(null))
    	assertFalse("map.containsValue(null)", snapshot.containsValue(null))
    	assertTrue("map.containsKey(one)", snapshot.containsKey(two))
    	assertTrue("map.containsValue(1L)", snapshot.containsValue(2L))
    	assertFalse("map.empty", snapshot.empty)
    	assertFalse("map.keySet.empty", snapshot.keySet.empty)
    	assertFalse("map.values.empty", snapshot.values.empty)
    	assertFalse("map.entrySet.empty", snapshot.entrySet.empty)
    	assertEquals("map.size", 1, snapshot.size)
    	assertEquals("map.keySet.size", 1, snapshot.keySet.size)
    	assertEquals("map.values.size", 1, snapshot.values.size)
    	assertEquals("map.entrySet.size", 1, snapshot.entrySet.size)
    	assertTrue("map.keySet.toArray", Arrays.equals(#[two], snapshot.keySet.toArray))
    	assertTrue("map.values.toArray", Arrays.equals(#[2L], snapshot.values.toArray))
    	val sesa = snapshot.entrySet.toArray(<Map.Entry<?,?>>newArrayOfSize(1))
    	assertNotNull("map.entrySet.toArray", sesa)
    	assertEquals("map.entrySet.toArray.length", 1, sesa.length)
    	val sesa0 = sesa.get(0)
    	assertNotNull("map.entrySet.toArray[0]", sesa0)
    	assertEquals("map.entrySet.toArray[0].key", two, sesa0.key)
    	assertEquals("map.entrySet.toArray[0].value", 2L, sesa0.value)

    	val siterK = snapshot.keySet.iterator
    	assertTrue("map.keySet.iterator.hasNext", siterK.hasNext)
    	assertEquals("map.keySet.iterator.next", two, siterK.next)
    	assertFalse("map.keySet.iterator.hasNext", siterK.hasNext)

    	val siterV = snapshot.values.iterator
    	assertTrue("map.values.iterator.hasNext", siterV.hasNext)
    	assertEquals("map.values.iterator.next", 2L, siterV.next)
    	assertFalse("map.values.iterator.hasNext", siterV.hasNext)

    	val siterE = snapshot.entrySet.iterator
    	assertTrue("map.entrySet.iterator.hasNext", siterE.hasNext)
    	val se = siterE.next
    	assertNotNull("map.entrySet.iterator.next", se)
    	assertEquals("map.entrySet.iterator.next.key", two, se.key)
    	assertEquals("map.entrySet.iterator.next.value", 2L, se.value)
    	assertFalse("map.entrySet.iterator.hasNext", siterE.hasNext)
	}

	@Test
	public def void testBeanPath() {
    	val map = new HashMap<String,Long>
     	val one = "one"
    	val two = "two"
    	val three = "three"
    	map.put(one, 1L)
    	map.put(two, 2L)
    	map.put(three, 3L)

    	val mmt = new MyMapType
    	mmt.map.putAll(map)

    	val path = new BeanPath(JavaMeta.MAP_CONTENT_PROP)
    	val expected = new ArrayList(map.values)
    	for (o : mmt.map.resolvePath(path, true)) {
    		assertTrue("remove("+o+")", expected.remove(o))
    	}
		assertTrue("expected.empty", expected.empty)

    	val pathTwo = new BeanPath(JavaMeta.MAP_CONTENT_PROP, #[two])
    	val iter = mmt.map.resolvePath(pathTwo, true).iterator
		assertTrue("iter.hasNext", iter.hasNext)
    	assertEquals("iter.next", 2L, iter.next)
		assertFalse("iter.hasNext", iter.hasNext)
	}

	@Test
	public def void testMapFixedKey() {
    	val mmt = new MyMapType
    	assertNotNull("nonfixed", mmt.nonfixed)
    	assertNotNull("fixedKey", mmt.fixedKey)
    	var failed = false
    	try {
    		mmt.nonfixed.put("key", null)
    	} catch (RuntimeException e) {
    		failed = true
    	}
		assertFalse("nonfixed key must accept subtype", failed)
    	try {
    		mmt.fixedKey.put("key", null)
    	} catch (RuntimeException e) {
    		failed = true
    	}
		assertTrue("fixedKey key must NOT accept subtype", failed)
	}

	@Test
	public def void testMapFixedValue() {
    	val mmt = new MyMapType
    	assertNotNull("nonfixed", mmt.nonfixed)
    	assertNotNull("fixedValue", mmt.fixedValue)
    	var failed = false
    	try {
    		mmt.nonfixed.put("key", "value")
    	} catch (RuntimeException e) {
    		failed = true
    	}
		assertFalse("nonfixed value must accept subtype", failed)
    	try {
    		mmt.fixedValue.put("key", "value")
    	} catch (RuntimeException e) {
    		failed = true
    	}
		assertTrue("fixed value must NOT accept subtype", failed)
	}

    @Test
    public def void testNullValueNotAllowed() {
    	val mmt = new MyMapType
    	var failed = false
    	try {
	    	mmt.nonNullValueMap.put("one", null)
    	} catch (RuntimeException e) {
    		failed = true
    	}
		assertTrue("value cannot be null", failed)
	}
}