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

import java.util.Collection;

import com.blockwithme.meta.Property;
import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans.Interceptor;
import com.blockwithme.meta.beans._BeanBase;
import com.blockwithme.murmur.MurmurHash;

/**
 * BeanBase impl for all data/bean objects (maybe remove requirement later)
 *
 * This class is written in Java, due to the inability of Xtend to
 * use bitwise operators!
 *
 * @author monster
 */
public abstract class BeanBaseImpl implements _BeanBase {
    /** Are we immutable? */
    private boolean immutable;
    /** 64 "dirty" flags; maximum 64 properties! */
    private long dirty;
    /** Our meta type */
    private Type<?> type;
    /** Lazily cached toString result (null == not computed yet) */
    private String toString;
    /** Lazily cached hashCode64 result (0 == not computed yet) */
    private long hashCode64;
    /**
     * Optional "delegate"; must have the same type as "this".
     * Allows re-using the same generated code for "wrappers" ...
     */
    protected _BeanBase delegate;
    /**
     * The required interceptor. It allows customizing the behavior of Beans
     * while only generating a single implementation per type.
     */
    protected Interceptor interceptor;

    /** Resets the cached state */
    private void resetCachedState() {
        hashCode64 = 0;
        toString = null;
    }

    /** Returns our type */
    public final Type<?> getType() {
        return type;
    }

    /** Returns true if we are immutable */
    public final boolean isImmutable() {
        return immutable;
    }

    /** Returns true if some property changed */
    public final boolean isDirty() {
        return dirty != 0;
    }

    /** Returns true if the specified property change */
    public final boolean isDirty(final Property<?, ?> prop) {
        return (dirty & (1L >> indexOf(prop))) != 0;
    }

    /** Returns the index to use for this property. */
    private int indexOf(final Property<?, ?> prop) {
        final int result = prop.inheritedPropertyId(type);
        if (result < 0) {
            throw new IllegalArgumentException("Property " + prop.fullName
                    + " unknown in " + type.fullName);
        }
        return result;
    }

    /** Marks the specified property as changed */
    public final void setDirty(final Property<?, ?> prop) {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        dirty |= (1L >> indexOf(prop));
        // Setting the dirty flag also means the content will propably change
        // so we reset the cached state.
        resetCachedState();
    }

    /** Clears all the dirty flags */
    public final void clean() {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        if (dirty != 0) {
            dirty = 0;
            // dirty has a special meaning, when used wit a delegate.
            // This could cause the apparent "content" of the bean to change.
            if (delegate != null) {
                resetCachedState();
            }
        }
    }

    /** Adds all the changed properties to "changed" */
    public final void getChangedProperty(
            final Collection<Property<?, ?>> changed) {
        changed.clear();
        if (isDirty()) {
            for (final Property<?, ?> p : type.properties) {
                if (isDirty(p)) {
                    changed.add(p);
                }
            }
        }
    }

    /** Returns the 64 bit hashcode */
    public final long hashCode64() {
        if (hashCode64 == 0) {
            hashCode64 = MurmurHash.hash64(toString());
            if (hashCode64 == 0) {
                hashCode64 = 1;
            }
        }
        return hashCode64;
    }

    /** Returns the 32 bit hashcode */
    @Override
    public final int hashCode() {
        final long value = hashCode64();
        return (int) (value ^ (value >>> 32));
    }

    /** Computes the JSON representation */
    public final void toJSON(final Appendable appendable) {
        new JSONBeanSerializer(appendable, this).visit();
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
        final BeanBaseImpl other = (BeanBaseImpl) obj;
        if (hashCode64() != other.hashCode64()) {
            return false;
        }
        // Inequality here is very unlikely.
        // Since we, currently, build the hashCode64 on the toString text
        // We know it was already computed, and so is a cheap way to compare.
        return toString().equals(other.toString());
    }

    /** Returns the delegate */
    public final _BeanBase getDelegate() {
        return delegate;
    }

    /** Sets the delegate */
    public final void setDelegate(final _BeanBase delegate) {
        if (this.delegate != delegate) {
            if ((delegate != null) && (delegate.getClass() != getClass())) {
                throw new IllegalArgumentException("Expected type: "
                        + getClass() + " Actual type: " + delegate.getClass());
            }
            if (delegate == this) {
                throw new IllegalArgumentException(
                        "Self-reference not allowed!");
            }
            // Does NOT affect "dirty state"
            this.delegate = delegate;
            // This could cause the apparent "content" of the bean to change.
            resetCachedState();
        }
    }

    /** Returns the interceptor */
    public final Interceptor getInterceptor() {
        return interceptor;
    }

    /** Sets the interceptor; cannot be null */
    public final void setInterceptor(final Interceptor interceptor) {
        if (this.interceptor != interceptor) {
            if (interceptor == null) {
                throw new IllegalArgumentException("interceptor cannot be null");
            }
            // Does NOT affect "dirty state"
            this.interceptor = interceptor;
            // This could cause the apparent "content" of the bean to change.
            resetCachedState();
        }
    }

//    /** Copies the content of another instance of the same type. */
//    private void copyFrom(final BeanBaseImpl other) {
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
