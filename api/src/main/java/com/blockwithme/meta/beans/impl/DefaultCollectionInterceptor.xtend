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
package com.blockwithme.meta.beans.impl

import com.blockwithme.meta.beans.ObjectCollectionInterceptor;
import com.blockwithme.meta.beans._Bean;

/**
 * Singleton, used for all collections of objects "beans".
 * Simply delegates back to the bean, marking it as dirty if needed.
 *
 * @author monster
 */
class DefaultCollectionInterceptor<E> extends DefaultInterceptor
implements ObjectCollectionInterceptor<E> {

    /** Default instance */
    public static val INSTANCE = new DefaultCollectionInterceptor()

	override getObjectAtIndex(_Bean instance, int index, E value) {
		value
	}

	override setObjectAtIndex(_Bean instance, int index, E oldValue, E newValue) {
        if (oldValue != newValue) {
        	// We generate an Integer Object here; no easy way around it.
			objectPropertyChanged(instance, index, index, oldValue, newValue)
        }
        newValue
	}

	override addObjectAtIndex(_Bean instance, int index, E newValue, boolean followingElementsChanged) {
    	// We generate an Integer Object here; no easy way around it.
		objectPropertyChanged(instance, index, index, null, newValue)
		if (followingElementsChanged) {
			instance.setSelectedFrom(index)
		}
		newValue
	}

	override removeObjectAtIndex(_Bean instance, int index, E oldValue, boolean followingElementsChanged) {
    	// We generate an Integer Object here; no easy way around it.
		objectPropertyChanged(instance, index, index, oldValue, null)
		if (followingElementsChanged) {
			instance.setSelectedFrom(index)
		}
	}

	override clear(_Bean instance) {
		instance.setSelectedFrom(0)
	}

}