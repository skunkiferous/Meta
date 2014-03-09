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
package com.blockwithme.meta.beans.impl;

import java.io.IOException;
import java.lang.reflect.UndeclaredThrowableException;
import java.util.Collection;
import java.util.Objects;

import com.blockwithme.meta.ObjectProperty;
import com.blockwithme.meta.Property;
import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans.Entity;
import com.blockwithme.meta.beans.Interceptor;
import com.blockwithme.meta.beans._Bean;
import com.blockwithme.murmur.MurmurHash;

/**
 * Bean impl for all data/bean objects.
 *
 * This class is written in Java, due to the inability of Xtend to
 * use bitwise operators!
 *
 * @author monster
 */
public class _BeanImpl implements _Bean {
    /** Empty long[], used in selectedArray */
    private static final long[] NO_LONG = new long[0];

    /** Our meta type */
    private final Type<?> metaType;

    /**
     * The required interceptor. It allows customizing the behavior of Beans
     * while only generating a single implementation per type.
     */
    protected Interceptor interceptor = DefaultInterceptor.INSTANCE;

    /**
     * Optional "delegate"; must have the same type as "this".
     * Allows re-using the same generated code for "wrappers" ...
     */
    protected _Bean delegate;

    /** Are we immutable? */
    private boolean immutable;

    /**
     * The "parent" Bean, if any.
     *
     * Bean do not support cycles in the structure, and so are limited to tree
     * structures. This means we can only ever have one parent maximum. This
     * parent field is *managed automatically*, and allows traversing the tree
     * in all directions.
     */
    private _Bean parent;

    /** 64 "selected" flags */
    private long selected;

    /** More "selected" flags, if 64 is not enough, or if the number varies */
    private final long[] selectedArray;

    /** The change counter */
    private int changeCounter;

    /**
     * Lazily cached toString result (null == not computed yet)
     * Cleared automatically when the "state" of the Bean changes.
     */
    private String toString;

    /**
     * Lazily cached hashCode64 result (0 == not computed yet)
     * Cleared automatically when the "state" of the Bean changes.
     */
    private long toStringHashCode64;

    /** Resets the cached state (when something changes) */
    private void resetCachedState() {
        toStringHashCode64 = 0;
        toString = null;
    }

    /** The constructor; metaType is required. */
    public _BeanImpl(final Type<?> metaType) {
        Objects.requireNonNull(metaType, "metaType");
        // Make sure we get the "right" metaType
        final String myType = getClass().getName();
        final int lastDot = myType.lastIndexOf('.');
        final String myPkg = myType.substring(0, lastDot);
        final int preLastDot = myPkg.lastIndexOf('.');
        final String parentPkg = myPkg.substring(0, preLastDot);
        final String myInterfaceName = parentPkg + "."
                + myType.substring(lastDot + 1, myType.length() - 4);
        if (!myInterfaceName.equals(metaType.type.getName())) {
            throw new IllegalArgumentException("Type should be "
                    + myInterfaceName + " but was " + metaType.type.getName());
        }
        this.metaType = metaType;
        // Setup the selectedArray. The idea is that small objects do not
        // require an additional long[] instance, making small more lightweight.
        final int propertyCount = metaType.inheritedPropertyCount;
        int arraySizePlusOne = propertyCount / 64;
        if (propertyCount % 64 != 0) {
            arraySizePlusOne++;
        }
        selectedArray = (arraySizePlusOne == 1) ? NO_LONG
                : new long[arraySizePlusOne - 1];
    }

    /** Returns our metaType. Cannot be null. */
    @Override
    public final Type<?> getMetaType() {
        return metaType;
    }

    /** Returns true if we are immutable */
    @Override
    public final boolean isImmutable() {
        return immutable;
    }

    /** Sets the immutable flag to true. */
    @Override
    public final void makeImmutable() {
        immutable = true;
    }

    /** Returns true if some property is "selected" */
    @Override
    public final boolean isSelected() {
        if (selected != 0) {
            return true;
        }
        final long[] array = selectedArray;
        for (final long l : array) {
            if (l != 0) {
                return true;
            }
        }
        return false;
    }

    /** Returns true, if some property was "selected", either in self, or in children */
    @Override
    public final boolean isSelectedRecursive() {
        if (isSelected()) {
            return true;
        }
        for (@SuppressWarnings("rawtypes")
        final ObjectProperty p : metaType.inheritedObjectProperties) {
            if (p.bean) {
                @SuppressWarnings("unchecked")
                final _Bean value = (_Bean) p.getObject(this);
                if (value != null) {
                    if (value.isSelectedRecursive()) {
                        return true;
                    }
                    value.setSelectionRecursive();
                }
            }
        }
        return false;
    }

    /** Returns true if the specified property was selected */
    @Override
    public final boolean isSelected(final Property<?, ?> prop) {
        final int index = indexOf(prop);
        if (index < 64) {
            return (selected & (1L << index)) != 0;
        }
        final long sel = selectedArray[index / 64 - 1];
        return (sel & (1L << (index % 64))) != 0;
    }

    /** Returns the index to use for this property. */
    private int indexOf(final Property<?, ?> prop) {
        final int result = prop.inheritedPropertyId(metaType);
        if (result < 0) {
            throw new IllegalArgumentException("Property " + prop.fullName
                    + " unknown in " + metaType.fullName);
        }
        return result;
    }

    /** Marks the specified property as selected */
    @Override
    public final void setSelected(final Property<?, ?> prop) {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        changeCounter++;
        final int index = indexOf(prop);
        if (index < 64) {
            selected |= (1L << index);
        } else {
            selectedArray[index / 64 - 1] |= (1L << (index % 64));
        }
        // Setting the selected flag also means the content will probably change
        // so we reset the cached state.
        resetCachedState();
    }

    /** Clears all the selected flags */
    @Override
    public final void clearSelection(final boolean alsoChangeCounter,
            final boolean recursively) {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        if (isSelected()) {
            selected = 0;
            // It's always safe to set all bits to 0, even the ones we don't use.
            final long[] array = selectedArray;
            final int length = array.length;
            for (int i = 0; i < length; i++) {
                array[i] = 0;
            }
            // selected has a special meaning, when used with a delegate.
            // This could cause the apparent "content" of the bean to change.
            if (delegate != null) {
                resetCachedState();
            }
        }
        if (alsoChangeCounter) {
            changeCounter = 0;
        }
        if (recursively) {
            for (@SuppressWarnings("rawtypes")
            final ObjectProperty p : metaType.inheritedObjectProperties) {
                if (p.bean) {
                    @SuppressWarnings("unchecked")
                    final _Bean value = (_Bean) p.getObject(this);
                    if (value != null) {
                        value.clearSelection(alsoChangeCounter, true);
                    }
                }
            }
        }
    }

    /** Adds all the selected properties to "selected" */
    @Override
    public final void getSelectedProperty(
            final Collection<Property<?, ?>> selected) {
        selected.clear();
        if (isSelected()) {
            for (final Property<?, ?> p : metaType.inheritedProperties) {
                if (isSelected(p)) {
                    selected.add(p);
                }
            }
        }
    }

    /** Sets all selected flags to true, including the children */
    @Override
    public final void setSelectionRecursive() {
        selected = -1L;
        final long[] array = selectedArray;
        final int length = array.length;
        for (int i = 0; i < length; i++) {
            array[i] = -1L;
        }
        final int rest = metaType.inheritedPropertyCount % 64;
        if (rest != 0) {
            // If we were to set too many bits to 1, then isSelected() would return the wrong value
            if (length == 0) {
                selected = (1L << rest) - 1L;
            } else {
                array[length - 1] = (1L << rest) - 1L;
            }
        }
        for (@SuppressWarnings("rawtypes")
        final ObjectProperty p : metaType.inheritedObjectProperties) {
            if (p.bean) {
                @SuppressWarnings("unchecked")
                final _Bean value = (_Bean) p.getObject(this);
                if (value != null) {
                    value.setSelectionRecursive();
                }
            }
        }
    }

    /** Returns the 64 bit hashcode of toString */
    @Override
    public final long getToStringHashCode64() {
        if (toStringHashCode64 == 0) {
            toStringHashCode64 = MurmurHash.hash64(toString());
            if (toStringHashCode64 == 0) {
                toStringHashCode64 = 1;
            }
        }
        return toStringHashCode64;
    }

    /** Returns the 32 bit hashcode */
    @Override
    public final int hashCode() {
        final long value = getToStringHashCode64();
        return (int) (value ^ (value >>> 32));
    }

    /** Computes the JSON representation */
    @Override
    public final void toJSON(final Appendable appendable) {
        try {
            final JacksonSerializer j = JacksonSerializer
                    .newSerializer(appendable);
            j.visit(this);
            j.generator.flush();
            j.generator.close();
        } catch (final IOException e) {
            throw new UndeclaredThrowableException(e);
        }
    }

    /** Returns the String representation */
    @Override
    public final String toString() {
        if (toString == null) {
            // Use JSON format
            final StringBuilder buf = new StringBuilder(1024);
            toJSON(buf);
            toString = buf.toString();
        }
        return toString;
    }

    /** Compares for equality with another object */
    @Override
    public final boolean equals(final Object obj) {
        if ((obj == null) || (obj.getClass() != getClass())) {
            return false;
        }
        if (obj == this) {
            return true;
        }
        final _BeanImpl other = (_BeanImpl) obj;
        if (getToStringHashCode64() != other.getToStringHashCode64()) {
            return false;
        }
        // Inequality here is very unlikely.
        // Since we, currently, build the hashCode64 on the toString text
        // We know it was already computed, and so is a cheap way to compare.
        return toString().equals(other.toString());
    }

    /** Returns the delegate */
    @Override
    public final _Bean getDelegate() {
        return delegate;
    }

    /** Sets the delegate */
    @Override
    public final void setDelegate(final _Bean delegate) {
        if (this.delegate != delegate) {
            if ((delegate != null) && (delegate.getClass() != getClass())) {
                throw new IllegalArgumentException("Expected type: "
                        + getClass() + " Actual type: " + delegate.getClass());
            }
            if (delegate == this) {
                throw new IllegalArgumentException(
                        "Self-reference not allowed!");
            }
            // Does NOT affect "selected state"
            this.delegate = delegate;
            // This could cause the apparent "content" of the bean to change.
            resetCachedState();
            if (delegate == null) {
                interceptor = DefaultInterceptor.INSTANCE;
            } else {
                interceptor = WrapperInterceptor.INSTANCE;
            }
        }
    }

    /** Returns the interceptor */
    @Override
    public final Interceptor getInterceptor() {
        return interceptor;
    }

    /** Sets the interceptor; cannot be null */
    @Override
    public final void setInterceptor(final Interceptor interceptor) {
        if (this.interceptor != interceptor) {
            if (interceptor == null) {
                throw new IllegalArgumentException("interceptor cannot be null");
            }
            // Does NOT affect "selected state"
            this.interceptor = interceptor;
            // This could cause the apparent "content" of the bean to change.
            resetCachedState();
        }
    }

    /** Returns the "parent" Bean, if any. */
    @Override
    public final _Bean getParent() {
        return parent;
    }

    /** Sets the "parent" Bean, if any. */
    @Override
    public final void setParent(final _Bean parent) {
        if (this instanceof Entity) {
            if (parent != null) {
                throw new UnsupportedOperationException(getClass().getName()
                        + ": Entities do not have parents");
            }
        }
        this.parent = parent;
    }

    /** Returns the "root" Bean, if any. */
    @Override
    public final _Bean getRoot() {
        _Bean result = null;
        // parent is always null for Entities
        if (parent != null) {
            result = parent;
            _Bean p = result.getParent();
            while (p != null) {
                result = p;
                p = result.getParent();
            }
        }
        return result;
    }

    /** Returns true, if this Bean has the same (non-null) root as the Bean passed as parameter */
    @Override
    public final boolean hasSameRoot(final _Bean other) {
        _Bean root;
        return (other != null)
                && ((this == other) || ((root = getRoot()) != null)
                        && (root == other.getRoot()));
    }

    /** Returns the current value of the change counter */
    @Override
    public final int getChangeCounter() {
        return changeCounter;
    }

    /** Sets the current value of the change counter */
    @Override
    public final void setChangeCounter(final int newValue) {
        changeCounter = newValue;
    }

//    /** Copies the content of another instance of the same type. */
//    private void copyFrom(final BeanImpl other) {
//        if (other == null) {
//            throw new IllegalArgumentException("other cannot be null");
//        }
//        if (other.getClass() != getClass()) {
//            throw new IllegalArgumentException("Expected type: "
//                    + getClass() + " Actual type: " + other.getClass());
//        }
//        // TODO
//    }
}
