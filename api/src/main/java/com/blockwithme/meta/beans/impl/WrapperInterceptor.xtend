/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
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

import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.beans._Bean

/**
 * Interceptor for "wrapper" beans.
 *
 * @author monster
 */
class WrapperInterceptor extends DefaultInterceptor {
    /** Default instance */
    public static val INSTANCE = new WrapperInterceptor()

	override getBooleanProperty(_Bean instance, BooleanProperty prop, boolean value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getBoolean(delegate)
	}

	override getByteProperty(_Bean instance, ByteProperty prop, byte value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getByte(delegate)
	}

	override getCharacterProperty(_Bean instance, CharacterProperty prop, char value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getChar(delegate)
	}

	override getShortProperty(_Bean instance, ShortProperty prop, short value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getShort(delegate)
	}

	override getIntegerProperty(_Bean instance, IntegerProperty prop, int value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getInt(delegate)
	}

	override getFloatProperty(_Bean instance, FloatProperty prop, float value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getFloat(delegate)
	}

	override getDoubleProperty(_Bean instance, DoubleProperty prop, double value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getDouble(delegate)
	}

	override getLongProperty(_Bean instance, LongProperty prop, long value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        return prop.getLong(delegate)
	}

	override <E> getObjectProperty(_Bean instance, ObjectProperty<?, E> prop, E value) {
        val delegate = instance.getDelegate()
        if ((delegate === null) || instance.isSelected(prop)) {
            return value
        }
        val p = prop as ObjectProperty
        return p.getObject(delegate) as E
	}
}