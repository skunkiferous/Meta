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

import org.junit.Assert
import org.junit.Test

/**
 * @author monster
 *
 */
class SkillsTest extends BaseTst {
	@Test
	def void testCreatePlayer() {
		val player = Skills.CHARACTER_TYPE.get
		player.name = "John"
		player.hp.baseValue = 10.0
		player.strength.baseValue = 20.0
		player.dexterity.baseValue = 30.0

		Assert.assertTrue("Skills.DRUNK_TYPE.immutable", Skills.DRUNK_TYPE.immutable)
		val mod = Skills.DRUNK_TYPE.get(player)
		mod.apply(player, 0)

		player.update(3)

		Assert.assertEquals("player.strength", 25.0, player.strength.eval(null, 3), 0.01)
		Assert.assertEquals("player.dexterity", 15.0, player.dexterity.eval(null, 3), 0.01)

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