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
package com.blockwithme.meta.beans

import com.blockwithme.meta.BooleanProperty
import com.blockwithme.meta.ByteProperty
import com.blockwithme.meta.CharacterProperty
import com.blockwithme.meta.DoubleProperty
import com.blockwithme.meta.FloatProperty
import com.blockwithme.meta.IntegerProperty
import com.blockwithme.meta.LongProperty
import com.blockwithme.meta.ObjectProperty
import com.blockwithme.meta.Property
import com.blockwithme.meta.ShortProperty
import com.blockwithme.meta.Type
import java.util.Collection

/** Base for all data/bean objects */
public interface BeanBase {
	/** Returns the Type of the instance */
    def Type<?> getType()

	/** Returns the true if the instance is immutable */
    def boolean isImmutable()

	/** Returns the 64-bit hashcode */
    def long hashCode64()

//    /** Returns a full mutable copy */
//    def BeanBase copy()
//
//    /** Returns an immutable copy */
//    def BeanBase snapshot()
//
//    /** Returns a lightweight mutable copy */
//    def BeanBase wrapper()
}

/** "Internal" base for all data/bean objects */
public interface _BeanBase extends BeanBase {
	/** Returns true, if some property was changed */
    def boolean isDirty()

	/** Returns true, if the specified property was changed */
    def boolean isDirty(Property<?,?> prop)

	/** Marks the specified property as changed */
    def void setDirty(Property<?,?> prop)

	/** Adds all the changed properties to "changed" */
    def void getChangedProperty(Collection<Property<?,?>> changed)

	/** Cleans all dirty flags */
    def void clean()

	/** Returns the delegate, if any */
    def _BeanBase getDelegate()

	/** Sets the delegate (can be null) */
    def void setDelegate(_BeanBase delegate)

	/** Returns the interceptor (cannot be null) */
    def Interceptor getInterceptor()

	/** Sets the interceptor (cannot be null) */
    def void setInterceptor(Interceptor newInterceptor)

    /** Computes the JSON representation */
    def void toJSON(Appendable appendable)
}

/** Interceptor allows "delegation", "validation", ... */
public interface Interceptor {
	/** Intercept the read access to a boolean property */
    def boolean getBooleanProperty(_BeanBase instance, BooleanProperty<?,?,?> prop, boolean value)

	/** Intercept the write access to a boolean property */
    def boolean setBooleanProperty(_BeanBase instance, BooleanProperty<?,?,?> prop, boolean oldValue,
            boolean newValue)

	/** Intercept the read access to a byte property */
    def byte getByteProperty(_BeanBase instance, ByteProperty<?,?,?> prop, byte value)

	/** Intercept the write access to a boolean property */
    def byte setByteProperty(_BeanBase instance, ByteProperty<?,?,?> prop, byte oldValue,
            byte newValue)

	/** Intercept the read access to a char property */
    def char getCharacterProperty(_BeanBase instance, CharacterProperty<?,?,?> prop, char value)

	/** Intercept the write access to a char property */
    def char setCharacterProperty(_BeanBase instance, CharacterProperty<?,?,?> prop, char oldValue,
            char newValue)

	/** Intercept the read access to a short property */
    def short getShortProperty(_BeanBase instance, ShortProperty<?,?,?> prop, short value)

	/** Intercept the write access to a short property */
    def short setShortProperty(_BeanBase instance, ShortProperty<?,?,?> prop, short oldValue,
            short newValue)

	/** Intercept the read access to a int property */
    def int getIntegerProperty(_BeanBase instance, IntegerProperty<?,?,?> prop, int value)

	/** Intercept the write access to a int property */
    def int setIntegerProperty(_BeanBase instance, IntegerProperty<?,?,?> prop, int oldValue,
            int newValue)

	/** Intercept the read access to a float property */
    def float getFloatProperty(_BeanBase instance, FloatProperty<?,?,?> prop, float value)

	/** Intercept the write access to a float property */
    def float setFloatProperty(_BeanBase instance, FloatProperty<?,?,?> prop, float oldValue,
            float newValue)

	/** Intercept the read access to a double property */
    def double getDoubleProperty(_BeanBase instance, DoubleProperty<?,?,?> prop, double value)

	/** Intercept the write access to a double property */
    def double setDoubleProperty(_BeanBase instance, DoubleProperty<?,?,?> prop, double oldValue,
            double newValue)

	/** Intercept the read access to a long property */
    def long getLongProperty(_BeanBase instance, LongProperty<?,?,?> prop, long value)

	/** Intercept the write access to a long property */
    def long setLongProperty(_BeanBase instance, LongProperty<?,?,?> prop, long oldValue,
            long newValue)

	/** Intercept the read access to a Object property */
    def <E> E getObjectProperty(_BeanBase instance, ObjectProperty<?,E> prop, E value)

	/** Intercept the write access to a Object property */
    def <E> E setObjectProperty(_BeanBase instance, ObjectProperty<?,E> prop, E oldValue,
            E newValue)

}
