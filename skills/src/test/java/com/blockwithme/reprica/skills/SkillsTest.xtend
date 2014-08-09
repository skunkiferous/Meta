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
package com.blockwithme.reprica.skills

import com.blockwithme.meta.Property
import com.blockwithme.meta.beans._Bean

import org.junit.Assert
import org.junit.Test

/**
 * @author monster
 *
 */
class SkillsTest {
	static val hierarchy = Meta.BUILDER.newHierarchy(Meta.PACKAGE)

	@Test
	def void testCreatePlayer() {
		val player = Meta.PLAYER.create
		player.name = "John"
		player.hitpoints.baseValue = 10.0
		player.strength.baseValue = 20.0
		player.dexterity.baseValue = 30.0

		val absStrBuf = Meta.BASIC_EFFECT.create
		absStrBuf.effect.baseValue = 5

		val relDexDebuf = Meta.BASIC_EFFECT.create
		relDexDebuf.effect.baseValue = 0.5
		relDexDebuf.percent = true

		player.strength.effects += absStrBuf
		player.dexterity.effects += relDexDebuf

		Assert.assertEquals("player.strength", 25.0, player.strength.eval(null), 0.01)
		Assert.assertEquals("player.dexterity", 15.0, player.dexterity.eval(null), 0.01)

//		Assert.assertFalse("as_Bean.immutable", as_Bean.immutable)
//		Assert.assertTrue("as_Bean.immutable", as_Bean.immutable)
//		var exception = false
//		try {
//			person.age = 66
//		} catch(Throwable t) {
//			exception = true
//		}
//		Assert.assertTrue("person now immutable", exception)
//		Assert.assertEquals("person.age", 33, person.age)
	}
}