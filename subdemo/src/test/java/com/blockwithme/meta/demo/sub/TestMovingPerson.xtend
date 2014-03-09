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
import com.blockwithme.meta.demo.sub.impl.MovingPersonProvider
import org.junit.Assert
import org.junit.Test

/**
 * @author monster
 *
 */
class TestMovingPerson {
	val hierarchy = Meta.BUILDER.newHierarchy(com.blockwithme.meta.demo.Meta.PACKAGE, Meta.PACKAGE)

	@Test
	def testMovingPerson() {
		val person = new MovingPersonProvider().get
		person.setAge(42)
		person.setLandMovingSpeed(99.0f)
		person.setName("John")
		person.setProfession("Teacher")

		Assert.assertEquals(42, person.getAge())
		Assert.assertEquals(99.0f, person.getLandMovingSpeed(), 0.0001f)
		Assert.assertEquals("John", person.getName())
		Assert.assertEquals("Teacher", person.getProfession())
		Assert.assertEquals(hierarchy, (person as _Bean).metaType.hierarchy)
	}
}