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

import com.blockwithme.meta.demo.Person
import com.blockwithme.meta.demo.Root
import com.blockwithme.meta.beans.annotations.Bean

@Bean
interface LandMoving extends Root {
	/** Implementation for all Person objects. */
	class Impl {
		/** Returns true, if the LandMoving is "fast". */
		static def boolean getFast(LandMoving it) {
			landMovingSpeed >= 100
		}
	}
	/** Speed of land movement */
	float landMovingSpeed
}

@Bean(instance=true)
interface MovingPerson extends Person, LandMoving {
	/** Implementation for all Person objects. */
	class Impl {
		/** Returns a salutation, based on the name. */
		static def String getHello(MovingPerson it) {
			if (fast) "No time to talk!" else Person.Impl.getHello(it)
		}
	}
}