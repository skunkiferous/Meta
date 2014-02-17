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
 * Bean impl for all data/bean objects (maybe remove requirement later)
 *
 * This class is written in Java, due to the inability of Xtend to
 * use bitwise operators!
 *
 * @author monster
 */
public class _BeanImpl implements _Bean {
    /** Are we immutable? */
    private boolean immutable;
    /** 64 "selected" flags; maximum 64 properties! */
    private long selected;
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
    protected _Bean delegate;
    /**
     * The required interceptor. It allows customizing the behavior of Beans
     * while only generating a single implementation per type.
     */
    protected Interceptor interceptor = DefaultInterceptor.INSTANCE;

    /** The "parent" Bean, if any. */
    private _Bean parent;

    /** The change counter */
    private int changeCounter;

    /** Resets the cached state */
    private void resetCachedState() {
        hashCode64 = 0;
        toString = null;
    }

    /** Returns our type */
    @Override
    public final Type<?> getMetaType() {
        return type;
    }

    /** Returns true if we are immutable */
    @Override
    public final boolean isImmutable() {
        return immutable;
    }

    /** Returns true if some property selected */
    @Override
    public final boolean isSelected() {
        return selected != 0;
    }

    /** Returns true, if some property was selected, either in self, or in children */
    @Override
    public final boolean isSelectedRecursive() {
        if (isSelected()) {
            return true;
        }
        for (final ObjectProperty p : type.objectProperties) {
            final Object value = p.getObject(this);
            if (value instanceof _Bean) {
                if (((_Bean) value).isSelectedRecursive()) {
                    return true;
                }
            }
        }
        return false;
    }

    /** Returns true if the specified property change */
    public final boolean isSelected(final Property<?, ?> prop) {
        return (selected & (1L >> indexOf(prop))) != 0;
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

    /** Marks the specified property as selected */
    public final void setSelected(final Property<?, ?> prop) {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        changeCounter++;
        selected |= (1L >> indexOf(prop));
        // Setting the selected flag also means the content will probably change
        // so we reset the cached state.
        resetCachedState();
    }

    /** Clears all the selected flags */
    @Override
    public final void clearSelection() {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        if (selected != 0) {
            selected = 0;
            // selected has a special meaning, when used wit a delegate.
            // This could cause the apparent "content" of the bean to change.
            if (delegate != null) {
                resetCachedState();
            }
        }
    }

    /** Adds all the selected properties to "selected" */
    @Override
    public final void getSelectedProperty(
            final Collection<Property<?, ?>> selected) {
        selected.clear();
        if (isSelected()) {
            for (final Property<?, ?> p : type.properties) {
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
        for (final ObjectProperty p : type.objectProperties) {
            final Object value = p.getObject(this);
            if (value instanceof _Bean) {
                ((_Bean) value).setSelectionRecursive();
            }
        }
    }

    /** Returns the 64 bit hashcode */
    @Override
    public final long getHashCode64() {
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
        final long value = getHashCode64();
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
        if (getHashCode64() != other.getHashCode64()) {
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

    /** Returns true, if this Bean has the same root as the Bean passed as parameter */
    @Override
    public final boolean hasSameRoot(final _Bean other) {
        return (this == other)
                || (getRoot() == Objects.requireNonNull(other, "other")
                        .getRoot());
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
