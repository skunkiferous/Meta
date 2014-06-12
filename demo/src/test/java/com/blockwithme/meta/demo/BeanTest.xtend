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

import com.blockwithme.meta.demo.impl.SixtyFivePropsImpl
import com.blockwithme.meta.demo.impl.SixtyFivePropsProvider
import org.junit.Assert
import org.junit.Test
import java.util.Collection
import com.blockwithme.meta.demo.impl.PersonProvider
import com.blockwithme.meta.Property
import com.blockwithme.meta.beans._Bean
import com.blockwithme.meta.demo.impl.DemoTypeChildProvider
import com.blockwithme.meta.demo.impl.DemoTypeChildImpl
import com.blockwithme.meta.demo.impl.PersonImpl
import com.blockwithme.meta.beans.impl.WrapperInterceptor
import com.blockwithme.meta.beans.impl.DefaultInterceptor

/**
 * @author monster
 *
 */
class BeanTest {
	static val hierarchy = Meta.BUILDER.newHierarchy(com.blockwithme.meta.demo.Meta.PACKAGE, Meta.PACKAGE)

	@Test
	def void testImmutable() {
		val person = new PersonProvider().get
		person.age = 33
		person.name = "John"
		person.profession = "Admin"
		val as_Bean = person as _Bean
		Assert.assertFalse("as_Bean.immutable", as_Bean.immutable)
		as_Bean.makeImmutable
		Assert.assertTrue("as_Bean.immutable", as_Bean.immutable)
		var exception = false
		try {
			person.age = 66
		} catch(Throwable t) {
			exception = true
		}
		Assert.assertTrue("person now immutable", exception)
		Assert.assertEquals("person.age", 33, person.age)
	}

	/** Also tests toJSON(Appendable) */
	@Test
	def void testToString() {
		val person = new PersonProvider().get
		person.age = 33
		person.name = "John"
		person.profession = "Admin"
		Assert.assertEquals("person.toString",
		'{"#":0,"class":"com.blockwithme.meta.demo.impl.PersonImpl","age":33,"name":"John","profession":"Admin"}',
		person.toString)
	}

	@Test
	def void testEqualsHashCode() {
		val provider = new PersonProvider()
		val person1 = provider.get
		person1.age = 33
		person1.name = "John"
		person1.profession = "Admin"
		val person2 = provider.get
		person2.age = 33
		person2.name = "John"
		person2.profession = "Admin"
		Assert.assertNotSame(person1, person2)
		Assert.assertEquals(person1, person2)
		Assert.assertEquals("hashCode", person1.hashCode, person2.hashCode)
	}

	@Test
	def void testChild() {
		val dtc = new DemoTypeChildProvider().get as DemoTypeChildImpl
		val person = new PersonProvider().get as PersonImpl
		person.age = 33
		person.name = "John"
		person.profession = "Admin"
		dtc.childProp = person
		dtc.clearSelection(true, true)
		dtc.setSelectionRecursive
		Assert.assertTrue("dtc.selected1", dtc.selected)
		Assert.assertTrue("person.selected1", person.selected)
		Assert.assertTrue("dtc.selectedRecursive1", dtc.selectedRecursive)
		dtc.clearSelection(true, false)
		Assert.assertFalse("dtc.selected2", dtc.selected)
		Assert.assertTrue("person.selected2", person.selected)
		Assert.assertTrue("dtc.selectedRecursive2", dtc.selectedRecursive)
		Assert.assertSame("person.parent", dtc, person.parent)
		Assert.assertSame("person.root", dtc, person.root)
		Assert.assertEquals("dtc.root", null, dtc.root)
		dtc.childProp = null
		Assert.assertSame("person.parent", null, person.parent)
		Assert.assertSame("person.root", null, person.root)
	}

	@Test
	def void testWrapper() {
		val person1 = new PersonProvider().get as PersonImpl
		person1.age = 33
		person1.name = "John"
		person1.profession = "Admin"

		val person2 = person1.wrapper as PersonImpl
		Assert.assertEquals("person2.interceptor", WrapperInterceptor.INSTANCE, person2.interceptor)
		Assert.assertEquals("person2.age", 33, person2.age)
		Assert.assertEquals("person2.name", "John", person2.name)
		Assert.assertEquals("person2.profession", "Admin", person2.profession)

		person2.age = 16
		person2.name = "Susy"

		Assert.assertEquals("person2.age", 16, person2.age)
		Assert.assertEquals("person2.name", "Susy", person2.name)
		Assert.assertEquals("person1.age", 33, person1.age)
		Assert.assertEquals("person1.name", "John", person1.name)
		Assert.assertTrue("person2.isSelected(Meta.AGED_AGE)", person2.isSelected(Meta.AGED_AGE))
		Assert.assertTrue("person2.isSelected(Meta.NAMED_NAME)", person2.isSelected(Meta.NAMED_NAME))
		Assert.assertFalse("person2.isSelected(Meta.PERSON_PROFESSION)", person2.isSelected(Meta.PERSON_PROFESSION))

		Assert.assertEquals("person2.toString",
		'{"#":0,"class":"com.blockwithme.meta.demo.impl.PersonImpl","age":16,"name":"Susy","profession":"Admin"}',
		person2.toString)
	}

	@Test
	def void testCopy() {
		val provider = new PersonProvider()
		val person1 = provider.get
		person1.age = 33
		person1.name = "John"
		person1.profession = "Admin"
		(person1 as PersonImpl).makeImmutable
		val person2 = person1.copy
		Assert.assertNotSame(person1, person2)
		Assert.assertEquals(person1, person2)
		Assert.assertFalse("person2.immutable", person2.immutable)

		val dtc = new DemoTypeChildProvider().get as DemoTypeChildImpl
		dtc.childProp = person2
		val dtc2 = dtc.copy
		Assert.assertNotSame(dtc, dtc2)
		Assert.assertEquals(dtc, dtc2)
		Assert.assertNotSame(dtc.childProp, dtc2.childProp)
	}

	@Test
	def void testSnapshot() {
		val provider = new PersonProvider()
		val person1 = provider.get
		person1.age = 33
		person1.name = "John"
		person1.profession = "Admin"
		val person2 = person1.snapshot
		Assert.assertNotSame(person1, person2)
		Assert.assertEquals(person1, person2)
		Assert.assertTrue("person2.immutable", person2.immutable)
		val person3 = person2.snapshot
		Assert.assertSame(person2, person3)
	}

	@Test
	def void testNoSelection() {
		val obj = new SixtyFivePropsProvider().get as SixtyFivePropsImpl
		val type = obj.metaType
		val props = type.inheritedProperties
		Assert.assertEquals("type.propertyCount", 65, type.inheritedPropertyCount)
		Assert.assertFalse("obj.selected", obj.selected)
		Assert.assertFalse("obj.selectedRecursive", obj.selectedRecursive)
		for (p : props) {
			Assert.assertFalse("obj.selected("+p+")", obj.isSelected(p))
		}
		Assert.assertFalse("obj.selected(0)", obj.isSelected(props.get(0)))
		Assert.assertFalse("obj.selected(64)", obj.isSelected(props.get(64)))
	}

	@Test
	def void test00Selection() {
		val obj = new SixtyFivePropsProvider().get as SixtyFivePropsImpl
		val type = obj.metaType
		val props = type.inheritedProperties
		val changed = <Property>newArrayList()
		obj.getSelectedProperty(changed as Collection)
		Assert.assertEquals("type.propertyCount", 65, type.inheritedPropertyCount)
		Assert.assertFalse("obj.selected", obj.selected)
		Assert.assertFalse("obj.selectedRecursive", obj.selectedRecursive)
		Assert.assertEquals("obj.changeCounter", 0, obj.changeCounter)
		Assert.assertEquals("changed.size", 0, changed.size)
		obj.prop00 = true
		Assert.assertTrue("obj.selected", obj.selected)
		Assert.assertTrue("obj.selectedRecursive", obj.selectedRecursive)
		Assert.assertEquals("obj.changeCounter", 1, obj.changeCounter)
		val prop = props.get(0)
		for (p : props) {
			if (p !== prop) {
				Assert.assertFalse("obj.selected("+p+")", obj.isSelected(p))
			}
		}
		obj.getSelectedProperty(changed as Collection)
		Assert.assertEquals("changed.size", 1, changed.size)
		Assert.assertEquals("changed.get(0)", prop, changed.get(0))
		obj.clearSelection(false, false)
		obj.getSelectedProperty(changed as Collection)
		Assert.assertEquals("changed.size", 0, changed.size)
		Assert.assertEquals("obj.changeCounter", 1, obj.changeCounter)
		Assert.assertFalse("obj.selected", obj.selected)
	}

	@Test
	def void test64Selection() {
		val obj = new SixtyFivePropsProvider().get as SixtyFivePropsImpl
		val type = obj.metaType
		val props = type.inheritedProperties
		val changed = <Property>newArrayList()
		obj.getSelectedProperty(changed as Collection)
		Assert.assertEquals("type.propertyCount", 65, type.inheritedPropertyCount)
		Assert.assertFalse("obj.selected", obj.selected)
		Assert.assertFalse("obj.selectedRecursive", obj.selectedRecursive)
		Assert.assertEquals("obj.changeCounter", 0, obj.changeCounter)
		Assert.assertEquals("changed.size", 0, changed.size)
		obj.prop64 = true
		Assert.assertTrue("obj.selected", obj.selected)
		Assert.assertTrue("obj.selectedRecursive", obj.selectedRecursive)
		Assert.assertEquals("obj.changeCounter", 1, obj.changeCounter)
		val prop = props.get(64)
		for (p : props) {
			if (p !== prop) {
				Assert.assertFalse("obj.selected("+p+")", obj.isSelected(p))
			}
		}
		obj.getSelectedProperty(changed as Collection)
		Assert.assertEquals("changed.size", 1, changed.size)
		Assert.assertEquals("changed.get(0)", prop, changed.get(0))
		obj.clearSelection(true, false)
		obj.getSelectedProperty(changed as Collection)
		Assert.assertEquals("changed.size", 0, changed.size)
		Assert.assertEquals("obj.changeCounter", 0, obj.changeCounter)
		Assert.assertFalse("obj.selected", obj.selected)
	}

	@Test
	def void testSelectionRecursive() {
		val obj = new SixtyFivePropsProvider().get as SixtyFivePropsImpl
		val type = obj.metaType
		val props = type.inheritedProperties
		Assert.assertEquals("type.propertyCount", 65, type.inheritedPropertyCount)
		Assert.assertFalse("obj.selected", obj.selected)
		Assert.assertFalse("obj.selectedRecursive", obj.selectedRecursive)
		obj.setSelectionRecursive
		Assert.assertTrue("obj.selected", obj.selected)
		Assert.assertTrue("obj.selectedRecursive", obj.selectedRecursive)
		for (p : props) {
			Assert.assertTrue("obj.selected("+p+")", obj.isSelected(p))
		}
	}
}