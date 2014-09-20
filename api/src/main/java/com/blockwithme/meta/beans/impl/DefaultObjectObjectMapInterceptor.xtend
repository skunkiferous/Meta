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

import com.blockwithme.meta.beans.ObjectObjectMapInterceptor
import com.blockwithme.meta.beans._MapBean

/**
 * Singleton, used for all Maps of objects "beans".
 * Simply delegates back to the bean, marking it as dirty if needed.
 *
 * Since we have two "values" per "index" (key and value), we need to double
 * the index when setting selected indexes.
 *
 * @author monster
 */
class DefaultObjectObjectMapInterceptor<K,V> extends DefaultInterceptor
implements ObjectObjectMapInterceptor<K,V> {

    /** Default instance */
    public static val INSTANCE = new DefaultObjectObjectMapInterceptor()

	override getKeyAtIndex(_MapBean<K, V> instance, int index, K key) {
		key
	}

	override getValueAtIndex(_MapBean<K, V> instance, int index, V value) {
		value
	}

	override setKeyAtIndex(_MapBean<K, V> instance, int index, K oldKey, K newKey) {
        if (oldKey != newKey) {
			// TODO Somehow support the Property Validators and Listeners
			objectPropertyChanged(instance, index, index*2, oldKey, newKey)
        }
		newKey
	}

	override setValueAtIndex(_MapBean<K, V> instance, K key, int index, V oldValue, V newValue) {
        if (oldValue != newValue) {
			// TODO Somehow support the Property Validators and Listeners
			objectPropertyChanged(instance, key, index*2+1, oldValue, newValue)
        }
		newValue
	}

	override clear(_MapBean<K, V> instance) {
		instance.setSelectedFrom(0)
	}
}