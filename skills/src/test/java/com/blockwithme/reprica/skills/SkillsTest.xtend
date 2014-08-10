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
import com.blockwithme.util.server.UtilServerModule
import com.google.inject.Guice

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

		val absStrBuf = Skills.BASIC_EFFECT_TYPE.get
		absStrBuf.effect.baseValue = 5

		val relDexDebuf = Skills.BASIC_PERCENT_EFFECT_TYPE.get
		relDexDebuf.effect.baseValue = 0.5

		player.strength += absStrBuf
		player.dexterity += relDexDebuf

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