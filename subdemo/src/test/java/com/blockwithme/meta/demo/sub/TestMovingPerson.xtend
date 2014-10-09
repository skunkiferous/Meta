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
package com.blockwithme.meta.demo.sub

import com.blockwithme.meta.beans._Bean
import com.blockwithme.meta.Property
import com.blockwithme.meta.demo.sub.impl.MovingPersonProvider
import org.junit.Assert
import org.junit.Test
import java.util.ArrayList
import java.util.Arrays
import java.util.Collections
import com.blockwithme.meta.demo.impl.DemoTypeChildProvider
import com.blockwithme.meta.demo.impl.DemoTypeChildImpl

/**
 * @author monster
 *
 */
class TestMovingPerson extends BaseTst {
	val hierarchy = Meta.BUILDER.newHierarchy(com.blockwithme.meta.demo.Meta.PACKAGE, Meta.PACKAGE)

	@Test
	def testMovingPerson() {
		val person = new MovingPersonProvider().get
		person.setAge(42)
		person.setLandMovingSpeed(99.0f)
		person.setName("John")
		person.setProfession("Teacher")

		Assert.assertEquals(42, person.age)
		Assert.assertEquals(99.0f, person.landMovingSpeed, 0.0001f)
		Assert.assertEquals("John", person.name)
		Assert.assertEquals("Teacher", person.profession)
		Assert.assertEquals("Hello, Sir. John", person.hello)
		Assert.assertEquals(hierarchy, (person as _Bean).metaType.hierarchy)

		person.landMovingSpeed = 200
		Assert.assertEquals("No time to talk!", person.hello)

		val list = new ArrayList<Property<?,?>>
		list.addAll(Arrays.asList(Meta.MOVING_PERSON.inheritedProperties))
		list.addAll(Arrays.asList(Meta.MOVING_PERSON.inheritedVirtualProperties))
		Collections.sort(list)
		Assert.assertEquals("[com.blockwithme.meta.demo.Aged.age, com.blockwithme.meta.demo.Named.name, "
			+"com.blockwithme.meta.demo.Person.profession, com.blockwithme.meta.demo.Salutable.hello, "
			+"com.blockwithme.meta.demo.sub.LandMoving.fast, "
			+"com.blockwithme.meta.demo.sub.LandMoving.landMovingSpeed]", list.toString)
	}

	@Test
	def testFixedType() {
		val dtc = new DemoTypeChildProvider().get as DemoTypeChildImpl
		var failed = false
		try {
			dtc.childProp = new MovingPersonProvider().get
		} catch(RuntimeException e) {
			failed = true
		}
		Assert.assertTrue("DemoTypeChild.childProp accepted a Person subtype", failed)
	}
}