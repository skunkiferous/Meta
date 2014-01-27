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

import com.blockwithme.meta.beans.Interceptor
import com.blockwithme.meta.beans._BeanBase
import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty

/**
 * Singleton, used for all normal "beans".
 * Simply delegates back to the bean, marking it as dirty if needed.
 *
 * @author monster
 */
class DefaultInterceptor implements Interceptor {
    /** Default instance */
    public static val INSTANCE = new DefaultInterceptor()

	override getBooleanProperty(_BeanBase instance, BooleanProperty<?, ?, ?> prop, boolean value) {
        value
	}

	override setBooleanProperty(_BeanBase instance, BooleanProperty<?, ?, ?> prop, boolean oldValue, boolean newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getByteProperty(_BeanBase instance, ByteProperty<?, ?, ?> prop, byte value) {
        value
	}

	override setByteProperty(_BeanBase instance, ByteProperty<?, ?, ?> prop, byte oldValue, byte newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getCharacterProperty(_BeanBase instance, CharacterProperty<?, ?, ?> prop, char value) {
        value
	}

	override setCharacterProperty(_BeanBase instance, CharacterProperty<?, ?, ?> prop, char oldValue, char newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getShortProperty(_BeanBase instance, ShortProperty<?, ?, ?> prop, short value) {
        value
	}

	override setShortProperty(_BeanBase instance, ShortProperty<?, ?, ?> prop, short oldValue, short newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getIntegerProperty(_BeanBase instance, IntegerProperty<?, ?, ?> prop, int value) {
        value
	}

	override setIntegerProperty(_BeanBase instance, IntegerProperty<?, ?, ?> prop, int oldValue, int newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getFloatProperty(_BeanBase instance, FloatProperty<?, ?, ?> prop, float value) {
        value
	}

	override setFloatProperty(_BeanBase instance, FloatProperty<?, ?, ?> prop, float oldValue, float newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getDoubleProperty(_BeanBase instance, DoubleProperty<?, ?, ?> prop, double value) {
        value
	}

	override setDoubleProperty(_BeanBase instance, DoubleProperty<?, ?, ?> prop, double oldValue, double newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override getLongProperty(_BeanBase instance, LongProperty<?, ?, ?> prop, long value) {
        value
	}

	override setLongProperty(_BeanBase instance, LongProperty<?, ?, ?> prop, long oldValue, long newValue) {
        if (oldValue !== newValue) {
            instance.setDirty(prop)
        }
        newValue
	}

	override <E> getObjectProperty(_BeanBase instance, ObjectProperty<?, E> prop, E value) {
        value
	}

	override <E> setObjectProperty(_BeanBase instance, ObjectProperty<?, E> prop, E oldValue, E newValue) {
        if (oldValue != newValue) {
            instance.setDirty(prop)
        }
        newValue
	}
}