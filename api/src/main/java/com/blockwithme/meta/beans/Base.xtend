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
public interface Bean {
	/** Returns the true if the instance is immutable */
    def boolean isImmutable()

    /** Returns a full mutable copy */
    def Bean copy()

    /** Returns an immutable copy */
    def Bean snapshot()

    /** Returns a lightweight mutable copy */
    def Bean wrapper()
}

/**
 * "Internal" base for all data/bean objects.
 *
 * The "selected" state is usually used to keep track of the "dirty" state.
 */
public interface _Bean extends Bean {
	/** Returns the Type of the instance */
    def Type<?> getMetaType()

	/** Returns the 64-bit hashcode of toString (=> toJSON()) */
    def long getToStringHashCode64()

	/** Returns the current value of the change counter */
	def int getChangeCounter()

	/** Sets the current value of the change counter */
	def void setChangeCounter(int newValue)

	/** Returns the delegate, if any */
    def _Bean getDelegate()

	/** Sets the delegate (can be null) */
    def void setDelegate(_Bean delegate, boolean clearSelection,
            boolean alsoClearChangeCounter, boolean clearRecursively)

	/** Sets the delegate (can be null); does not clear selection */
    def void setDelegate(_Bean delegate)

	/** Returns the interceptor (cannot be null) */
    def Interceptor getInterceptor()

	/** Sets the interceptor (cannot be null) */
    def void setInterceptor(Interceptor newInterceptor)

    /** Returns the "parent" Bean, if any. */
    def _Bean getParent()

    /** Sets the "parent" Bean, if any. */
    def void setParent(_Bean parent)

	/** Returns true, if some property was selected */
    def boolean isSelected()

	/** Returns true, if some property was selected, either in self, or in children */
    def boolean isSelectedRecursive()

	/** Returns true, if the specified property was selected */
    def boolean isSelected(Property<?,?> prop)

	/** Marks the specified property as selected */
    def void setSelected(Property<?,?> prop)

	/** Adds all the selected properties to "selected" */
    def void getSelectedProperty(Collection<Property<?,?>> selected)

	/** Cleans all selected flags */
    def void clearSelection(boolean alsoChangeCounter, boolean recursively)

	/** Sets all selected flags to true, including the children */
    def void setSelectionRecursive()

    /** Sets the immutable flag to true. */
    def void makeImmutable()

    /** Computes the JSON representation */
    def void toJSON(Appendable appendable)

    /** Returns the "root" Bean, if any. */
    def _Bean getRoot()

    /** Returns true, if this Bean has the same (non-null) root as the Bean passed as parameter */
    def boolean hasSameRoot(_Bean other)
}


/**
 * The "context" within which an Entity exists.
 * It could be a JPA table, or anything that contains entities.
 */
public interface EntityContext {
	/**
	 * Returns the unique ID (within this context) of the entity.
	 * Null maps to null.
	 */
	def String getIDAsString(Entity entity)

	/** Finds/loads/creates/.. and entity, based on it's ID. */
	def Entity getEntityFromID(String idAsString)
}

/**
 * Entities are beans that have a "independent lifecycle".
 * If an Entity is the root of a Bean tree, it "owns" that tree.
 * Otherwise, it is just "referenced" by the tree.
 */
public interface Entity extends Bean {
	// NOP
}

/**
 * "Internal" Entity interface.
 */
public interface _Entity extends Entity, _Bean {
	/** Return the context owning this entity. */
	def EntityContext getEntityContext()

	/** Sets the context owning this entity. */
	def void setEntityContext(EntityContext entityContext)

	/** Returns the creation time in milliseconds */
	def long getCreationTime()

	/** Sets the creation time in milliseconds */
	def void setCreationTime(long creationTime)

	/** Returns the last modification time in milliseconds */
	def long getLastModificationTime()

	/** Sets the last modification time in milliseconds */
	def void setLastModificationTime(long lastModificationTime)
}

/** Interceptor allows "delegation", "validation", ... */
public interface Interceptor {
	/** Intercept the read access to a boolean property */
    def boolean getBooleanProperty(_Bean instance, BooleanProperty<?,?,?> prop, boolean value)

	/** Intercept the write access to a boolean property */
    def boolean setBooleanProperty(_Bean instance, BooleanProperty<?,?,?> prop, boolean oldValue,
            boolean newValue)

	/** Intercept the read access to a byte property */
    def byte getByteProperty(_Bean instance, ByteProperty<?,?,?> prop, byte value)

	/** Intercept the write access to a boolean property */
    def byte setByteProperty(_Bean instance, ByteProperty<?,?,?> prop, byte oldValue,
            byte newValue)

	/** Intercept the read access to a char property */
    def char getCharacterProperty(_Bean instance, CharacterProperty<?,?,?> prop, char value)

	/** Intercept the write access to a char property */
    def char setCharacterProperty(_Bean instance, CharacterProperty<?,?,?> prop, char oldValue,
            char newValue)

	/** Intercept the read access to a short property */
    def short getShortProperty(_Bean instance, ShortProperty<?,?,?> prop, short value)

	/** Intercept the write access to a short property */
    def short setShortProperty(_Bean instance, ShortProperty<?,?,?> prop, short oldValue,
            short newValue)

	/** Intercept the read access to a int property */
    def int getIntegerProperty(_Bean instance, IntegerProperty<?,?,?> prop, int value)

	/** Intercept the write access to a int property */
    def int setIntegerProperty(_Bean instance, IntegerProperty<?,?,?> prop, int oldValue,
            int newValue)

	/** Intercept the read access to a float property */
    def float getFloatProperty(_Bean instance, FloatProperty<?,?,?> prop, float value)

	/** Intercept the write access to a float property */
    def float setFloatProperty(_Bean instance, FloatProperty<?,?,?> prop, float oldValue,
            float newValue)

	/** Intercept the read access to a double property */
    def double getDoubleProperty(_Bean instance, DoubleProperty<?,?,?> prop, double value)

	/** Intercept the write access to a double property */
    def double setDoubleProperty(_Bean instance, DoubleProperty<?,?,?> prop, double oldValue,
            double newValue)

	/** Intercept the read access to a long property */
    def long getLongProperty(_Bean instance, LongProperty<?,?,?> prop, long value)

	/** Intercept the write access to a long property */
    def long setLongProperty(_Bean instance, LongProperty<?,?,?> prop, long oldValue,
            long newValue)

	/** Intercept the read access to a Object property */
    def <E> E getObjectProperty(_Bean instance, ObjectProperty<?,E> prop, E value)

	/** Intercept the write access to a Object property */
    def <E> E setObjectProperty(_Bean instance, ObjectProperty<?,E> prop, E oldValue,
            E newValue)

}
