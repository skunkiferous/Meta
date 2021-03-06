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
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.logging.Logger;

import com.blockwithme.meta.IProperty;
import com.blockwithme.meta.ObjectProperty;
import com.blockwithme.meta.ObjectPropertyListener;
import com.blockwithme.meta.Property;
import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans.Bean;
import com.blockwithme.meta.beans.BeanPath;
import com.blockwithme.meta.beans.Entity;
import com.blockwithme.meta.beans.Interceptor;
import com.blockwithme.meta.beans.Meta;
import com.blockwithme.meta.beans._Bean;
import com.blockwithme.util.base.SystemUtils;

/**
 * Bean impl for all data/bean objects.
 *
 * This class is written in Java, due to the inability of Xtend to
 * use bitwise operators!
 *
 * @author monster
 */
public abstract class _BeanImpl implements _Bean {

    /** Non-comparable Comparator. */
    protected static final Comparator<Object> NON_COMPARABLE_CMP = new Comparator<Object>() {
        @Override
        public int compare(final Object o1, final Object o2) {
            if (o1 == null) {
                if (o2 == null) {
                    return 0;
                }
                return -1;
            }
            if (o2 == null) {
                return 1;
            }
            final int hash1 = o1.hashCode();
            final int hash2 = o2.hashCode();
            if (hash1 == hash2) {
                if (o1.equals(o2)) {
                    return 0;
                }
                final int result = o1.toString().compareTo(o2.toString());
                if (result == 0) {
                    throw new IllegalStateException(
                            "Two objects have the same hashcode(" + hash1
                                    + ") and toString(" + o1
                                    + "), but are NOT equals!");
                }
                return result;
            }
            return hash1 - hash2;
        }
    };

    /**
     * Null-friendly Comparator can be used to compare Comparables with null,
     * as many Comparable fail when compared to null. The nulls are moved to
     * the end of the array.
     */
    @SuppressWarnings("rawtypes")
    protected static final Comparator<Comparable> NULL_FRIENDLY_CMP = new Comparator<Comparable>() {
        @SuppressWarnings("unchecked")
        @Override
        public int compare(final Comparable o1, final Comparable o2) {
            if (o1 == null) {
                if (o2 == null) {
                    return 0;
                }
                return 1;
            }
            if (o2 == null) {
                return -1;
            }
            return o1.compareTo(o2);
        }
    };

    /** An Iterable<_Bean>, over the property values */
    protected class SubBeanIterator implements Iterable<_Bean>, Iterator<_Bean> {

        /** The properties */
        @SuppressWarnings("rawtypes")
        private final ObjectProperty[] properties = metaType.inheritedObjectProperties;

        /** The next _Bean, if any. */
        private _Bean next;

        /** Next property index to check. */
        private int nextIndex;

        /** Optional other iterator. */
        private final Iterator<_Bean> other;

        @SuppressWarnings({ "rawtypes", "unchecked" })
        private void findNext() {
            while (nextIndex < properties.length) {
                final ObjectProperty p = properties[nextIndex];
                if (isBean(p)) {
                    next = (_Bean) p.getObject(_BeanImpl.this);
                    if (next != null) {
                        return;
                    }
                }
                nextIndex++;
            }
            next = null;
        }

        /** Constructor */
        public SubBeanIterator(final Iterator<_Bean> other) {
            findNext();
            final Iterator<_Bean> tmp = Collections.emptyIterator();
            this.other = (other != null) ? other : tmp;
        }

        /* (non-Javadoc)
         * @see java.lang.Iterable#iterator()
         */
        @Override
        public final Iterator<_Bean> iterator() {
            return this;
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#remove()
         */
        @Override
        public final void remove() {
            throw new UnsupportedOperationException();
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#hasNext()
         */
        @Override
        public final boolean hasNext() {
            return (next != null) || other.hasNext();
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#next()
         */
        @Override
        public final _Bean next() {
            if (next != null) {
                final _Bean result = next;
                nextIndex++;
                findNext();
                return result;
            }
            if (other.hasNext()) {
                return other.next();
            }
            throw new NoSuchElementException();
        }

    }

    /** Empty int[], used in selectedArray */
    private static final int[] NO_INT = new int[0];

    /** Reasonable maximum size. */
    private static final int MAX_SIZE = 65536;

    /** Our meta type */
    protected final Type<?> metaType;

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
    private _Bean parentBean;

    /**
     * The "root" Bean, if any. This root field is *managed automatically*.
     */
    private _Bean rootBean;

    /**
     * The key/index in the "parent", if any.
     * It is by convention the property full name, unless the parent is a _CollectionBean or a _MapBean.
     */
    private Object parentKey;

    /** 32 "selected" flags */
    private int selected;

    /** More "selected" flags, if 32 is not enough, or if the number varies */
    private int[] selectedArray;

    /** The change counter */
    private int changeCounter;

    /**
     * Lazily cached toString result (null == not computed yet)
     * Cleared automatically when the "state" of the Bean changes.
     */
    protected transient String toString;

    /** Speeds up, looking up Property indexes. */
    private transient Property<?, ?> lastIndexedProp;

    /** Speeds up, looking up Property indexes. */
    private transient int lastIndexedPropIndex = -1;

    /** The "under construction" flag */
    private transient boolean underConstruction;

    /** Resets the cached state (when something changes) */
    private void resetCachedState() {
        toString = null;
    }

    /** Compares two boolean */
    protected static final int compare(final boolean a, final boolean b) {
        return (a == b) ? 0 : (a ? 1 : -1);
    }

    /** Compares two byte */
    protected static final int compare(final byte a, final byte b) {
        return a - b;
    }

    /** Compares two short */
    protected static final int compare(final short a, final short b) {
        return a - b;
    }

    /** Compares two char */
    protected static final int compare(final char a, final char b) {
        return a - b;
    }

    /** Compares two int */
    protected static final int compare(final int a, final int b) {
        return a - b;
    }

    /** Compares two long */
    protected static final int compare(final long a, final long b) {
        return (a < b) ? -1 : ((a == b) ? 0 : 1);
    }

    /** Compares two float */
    protected static final int compare(final float a, final float b) {
        return Float.compare(a, b);
    }

    /** Compares two double */
    protected static final int compare(final double a, final double b) {
        return Double.compare(a, b);
    }

    /** Compares two Object */
    @SuppressWarnings({ "rawtypes", "unchecked" })
    protected static final int compare(final Comparable a, final Comparable b) {
        return (a == null) ? ((b == null) ? 0 : -1) : ((b == null) ? 1 : a
                .compareTo(b));
    }

    /** Returns true, if this ObjectProperty contains Beans. */
    private static boolean isBean(final ObjectProperty<?, ?, ?, ?> p) {
        return SystemUtils.isAssignableFrom(Bean.class, p.contentTypeClass);
    }

    /** For special beans with variable size, we can grow the selection range. */
    protected final void ensureSelectionCapacity(final int bitsMinCapacity) {
        if (bitsMinCapacity < 0) {
            throw new IllegalArgumentException("bitsMinCapacity="
                    + bitsMinCapacity);
        }
        if (bitsMinCapacity > MAX_SIZE) {
            throw new IllegalArgumentException("bitsMinCapacity ("
                    + bitsMinCapacity + ") > MAX_SIZE=" + MAX_SIZE);
        }
        final int[] array = selectedArray;
        final int oldArrayCapacity = array.length;
        int minCapacity = bitsMinCapacity / 32;
        if (bitsMinCapacity % 32 != 0) {
            minCapacity++;
        }
        // +1 because of the "selected" int field
        if (minCapacity > oldArrayCapacity + 1) {
            selectedArray = new int[minCapacity - 1];
            System.arraycopy(array, 0, selectedArray, 0, oldArrayCapacity);
        }
    }

    /** For special beans with variable size, we can clear the selection array. */
    protected final void clearSelectionArray() {
        selectedArray = NO_INT;
    }

    /** The constructor; metaType is required. */
    public _BeanImpl(final Type<?> metaType) {
        Objects.requireNonNull(metaType, "metaType");
        // Make sure we get the "right" metaType
        final String myType = getClass().getName();
        if (!myType.endsWith("Impl")) {
            throw new IllegalArgumentException("Class " + myType
                    + " should end with Impl");
        }
        final int lastDot = myType.lastIndexOf('.');
        final String myPkg = myType.substring(0, lastDot);
        if (!myPkg.endsWith(".impl")) {
            throw new IllegalArgumentException("Class " + myType
                    + " should be in package *.impl");
        }
        final int preLastDot = myPkg.lastIndexOf('.');
        final String parentPkg = myPkg.substring(0, preLastDot);
        final String myInterfaceName = parentPkg + "."
                + myType.substring(lastDot + 1, myType.length() - 4); // "Impl".length() == 4
        if (!myInterfaceName.equals(metaType.type.getName())) {
            throw new IllegalArgumentException("Type should be "
                    + myInterfaceName + "Impl but was "
                    + metaType.type.getName());
        }
        this.metaType = metaType;
        // Setup the selectedArray. The idea is that small objects do not
        // require an additional int[] instance, making small more lightweight.
        final int propertyCount = getSelectionCount();
        int arraySizePlusOne = propertyCount / 32;
        if (propertyCount % 32 != 0) {
            arraySizePlusOne++;
        }
        selectedArray = (arraySizePlusOne <= 1) ? NO_INT
                : new int[arraySizePlusOne - 1];
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
        final int[] array = selectedArray;
        for (final int l : array) {
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
        for (final _Bean value : getBeanIterator()) {
            if (value.isSelectedRecursive()) {
                return true;
            }
        }
        return false;
    }

    /** Returns true if the specified property was selected */
    @Override
    public final boolean isSelected(final Property<?, ?> prop) {
        return isSelected(indexOfProperty(prop));
    }

    /** Returns true if the specified property at the given index was selected */
    @Override
    public final boolean isSelected(final int index) {
        if (index < 32) {
            return (selected & (1 << index)) != 0;
        }
        final int sel = selectedArray[index / 32 - 1];
        return (sel & (1 << (index % 32))) != 0;
    }

    /** Returns the index to use for this property. */
    @Override
    public final int indexOfProperty(final Property<?, ?> prop) {
        final int result;
        if (prop == lastIndexedProp) {
            result = lastIndexedPropIndex;
        } else {
            result = prop.inheritedPropertyId(metaType);
            lastIndexedProp = prop;
            lastIndexedPropIndex = result;
        }
        if (result < 0) {
            throw new IllegalArgumentException("Property " + prop.fullName
                    + " unknown in " + metaType.fullName);
        }
        return result;
    }

    /** Marks the specified property as selected */
    @Override
    public final void setSelected(final Property<?, ?> prop) {
        setSelected(indexOfProperty(prop));
    }

    /** Marks the specified property as selected */
    @Override
    public final void setSelected(final int index) {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        changeCounter++;
        if (index < 32) {
            selected |= (1 << index);
        } else {
            selectedArray[index / 32 - 1] |= (1 << (index % 32));
        }
        // Setting the selected flag also means the content will probably change
        // so we reset the cached state.
        resetCachedState();
    }

    /**
     * Marks the specified property at the given index as selected,
     * as well as all the properties that follow.
     */
    @Override
    public final void setSelectedFrom(final int index) {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        changeCounter++;
        final int end = getSelectionCount();
        for (int i = index; i < end; i++) {
            if (i < 32) {
                selected |= (1 << i);
            } else {
                selectedArray[i / 32 - 1] |= (1 << (i % 32));
            }
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
            final int[] array = selectedArray;
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
            for (final _Bean value : getBeanIterator()) {
                value.clearSelection(alsoChangeCounter, true);
            }
        }
    }

    /** Adds all the selected properties to "selected" */
    @Override
    public final void getSelectedProperty(
            final Collection<Property<?, ?>> selected) {
        selected.clear();
        if (isSelected()) {
            final Property<?, ?>[] props = metaType.inheritedProperties;
            final int propertyCount = props.length;
            for (int i = 0; i < propertyCount; i++) {
                if (isSelected(i)) {
                    selected.add(props[i]);
                }
            }
        }
    }

    /** Sets all selected flags to true, including the children */
    @Override
    public final void setSelectionRecursive() {
        if (immutable) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        selected = -1;
        final int[] array = selectedArray;
        final int length = array.length;
        for (int i = 0; i < length; i++) {
            array[i] = -1;
        }
        final int rest = getSelectionCount() % 32;
        if (rest != 0) {
            // If we were to set too many bits to 1, then isSelected() would return the wrong value
            if (length == 0) {
                selected = (1 << rest) - 1;
            } else {
                array[length - 1] = (1 << rest) - 1;
            }
        }
        for (final _Bean value : getBeanIterator()) {
            if (!value.isImmutable())
                value.setSelectionRecursive();
        }
    }

    /** Returns the 32 bit hashcode */
    @Override
    public final int hashCode() {
        return toString().hashCode();
    }

    /** Computes the JSON representation */
    @Override
    public final void toJSON(final Appendable appendable) {
        try {
            final JacksonSerializer j = JacksonSerializer
                    .newSerializer(appendable);
            j.visit(getMetaType(), this);
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
        return (obj == this)
                || ((obj != null) && (obj.getClass() == getClass())
                        && (hashCode() == obj.hashCode()) && toString().equals(
                        obj.toString()));
    }

    /** Returns the delegate */
    @Override
    public _Bean getDelegate() {
        return delegate;
    }

    /** Sets the delegate (can be null); does not clear selection */
    @Override
    public final void setDelegate(final _Bean delegate) {
        setDelegate(delegate, false, false, false);
    }

    /** Sets the delegate */
    @Override
    public final void setDelegate(final _Bean delegate,
            final boolean clearSelection, final boolean alsoClearChangeCounter,
            final boolean clearRecursively) {
        if (this.delegate != delegate) {
            if ((delegate != null) && (delegate.getClass() != getClass())) {
                throw new IllegalArgumentException("Expected type: "
                        + getClass() + " Actual type: " + delegate.getClass());
            }
            _Bean d = delegate;
            while (d != null) {
                if (d == this) {
                    throw new IllegalArgumentException(
                            "Self-reference not allowed!");
                }
                d = d.getDelegate();
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
        if (clearSelection) {
            clearSelection(alsoClearChangeCounter, clearRecursively);
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
    public final _Bean getParentBean() {
        return parentBean;
    }

    /**
     * Sets the "parent" Bean and optional key/index, if any.
     */
    @Override
    public final void setParentBeanAndKey(final _Bean parent,
            final Object parentKey) {
        if ((parent != null) && (parentBean != null)) {
            throw new IllegalStateException(
                    "parent cannot be set when current parent is not null ("
                            + parentBean.getClass().getName() + ":"
                            + parentBean + ")");
        }
        if (this instanceof Entity) {
            if (parent != null) {
                throw new UnsupportedOperationException(getClass().getName()
                        + ": Entities do not have parents");
            }
            if (parentKey != null) {
                throw new UnsupportedOperationException(getClass().getName()
                        + ": Entities do not have parent keys");
            }
        }
        if ((parentKey != null) && (parent == null)) {
            throw new IllegalArgumentException(
                    "parentKey can only be set if parent is not null");
        }
        final _Bean oldValue = parent;
        this.parentBean = parent;
        this.parentKey = parentKey;
        updateRootBean();
        for (final ObjectPropertyListener listener : Meta._BEAN__PARENT_BEAN
                .getListeners((Type<_Bean>) getMetaType())) {
            listener.afterObjectPropertyChangeValidation(this,
                    Meta._BEAN__PARENT_BEAN, oldValue, parentBean);
        }
        onParentBeanAndKeyChange();
    }

    /** Updates the "root" Bean */
    @Override
    public final void updateRootBean() {
        final _Bean before = rootBean;
        if (parentBean == null) {
            rootBean = null;
        } else {
            final _Bean parentRoot = parentBean.getRootBean();
            if (parentRoot == null) {
                rootBean = parentBean;
            } else {
                rootBean = parentRoot;
            }
        }
        if (before != rootBean) {
            for (final _Bean b : getBeanIterator()) {
                b.updateRootBean();
            }
        }
    }

    /** Returns the key/index in the "parent", if any. */
    @Override
    public final Object getParentKey() {
        return parentKey;
    }

    /** Returns the "root" Bean, if any. */
    @Override
    public final _Bean getRootBean() {
        return rootBean;
    }

    /** Returns true, if this Bean has the same (non-null) root as the Bean passed as parameter */
    @Override
    public final boolean hasSameRoot(final _Bean other) {
        boolean result = false;
        if (other != null) {
            if (this == other) {
                result = true;
            } else {
                final _Bean otherRoot = other.getRootBean();
                if (otherRoot != null) {
                    final _Bean myRoot = getRootBean();
                    result = (myRoot == otherRoot);
                }
            }
        }
        return result;
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

    /** Increments the change counter. */
    protected final void incrementChangeCounter() {
        changeCounter++;
    }

    /** Copies the content of another instance of the same type. */
    @SuppressWarnings({ "rawtypes", "unchecked" })
    private void copyFrom(final _BeanImpl other, final boolean immutably) {
        if (other == null) {
            throw new IllegalArgumentException("other cannot be null");
        }
        if (other.getClass() != getClass()) {
            throw new IllegalArgumentException("Expected type: " + getClass()
                    + " Actual type: " + other.getClass());
        }
        if (other == this) {
            throw new IllegalArgumentException("other cannot be self");
        }
        for (final Property p : metaType.inheritedProperties) {
            if (!p.isImmutable()) {
                if (p instanceof ObjectProperty) {
                    if (isBean((ObjectProperty) p)) {
                        final _BeanImpl value = (_BeanImpl) p.getObject(other);
                        if (value != null) {
                            if (immutably) {
                                final _BeanImpl newVal = value.doSnapshot();
                                p.setObject(this, newVal);
                                // Setting immutable values does not set the parent
                                // But here we created it, so we want the parent to be set.
                                // Collection and Map content are copied as one big Property,
                                // such that parent and key/index should be correctly set.
                                // Therefore we assume a "normal" Property, and use the
                                // property name as key.
                                newVal.setParentBeanAndKey(this, p.fullName);
                            } else {
                                p.setObject(this, value.doCopy());
                            }
                        }
                        // else nothing to do
                    } else {
                        copyValue(p, other, immutably);
                    }
                } else {
                    p.copyValue(other, this);
                }
            } // else we assume it was somehow already set in the constructor...
        }
    }

    /** Allows collections to perform special copy implementations. */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    protected void copyValue(final Property p, final _BeanImpl other,
            final boolean immutably) {
        p.copyValue(other, this);
    }

    /** Make a new instance of the same type as self. */
    protected _BeanImpl newInstance() {
        final _BeanImpl result = (_BeanImpl) metaType.create();
        result.toString = toString;
        return result;
    }

    /** Returns a full mutable copy */
    protected final _BeanImpl doCopy() {
        final _BeanImpl result = newInstance();
        result.underConstruction = true;
        result.copyFrom(this, false);
        result.underConstruction = false;
        return result;
    }

    /** Returns an immutable copy */
    protected final _BeanImpl doSnapshot() {
        if (immutable) {
            return this;
        }
        final _BeanImpl result = newInstance();
        result.underConstruction = true;
        result.copyFrom(this, true);
        result.underConstruction = false;
        result.makeImmutable();
        return result;
    }

    /** Returns a lightweight mutable copy */
    protected final _BeanImpl doWrapper() {
        final _BeanImpl result = newInstance();
        result.setDelegate(this);
        return result;
    }

    /** Returns an Iterable<_Bean>, over the property values */
    protected Iterable<_Bean> getBeanIterator() {
        return new SubBeanIterator(null);
    }

    /** Returns the number of possible selections. */
    protected int getSelectionCount() {
        return metaType.inheritedPropertyCount;
    }

    /** Checks that the new value is either null or immutable. */
    protected final void checkNullOrImmutable(final Object newValue) {
        if ((newValue != null) && !underConstruction) {
            // TODO This is a work-around for creating immutable snapshots of beans that
            // contain collections. We should not simply assume that immutable values
            // are only set for collection properties during snapshots
            if (!(newValue instanceof _Bean)
                    || !((_Bean) newValue).isImmutable()) {
                throw new IllegalArgumentException(
                        "Collection/Map setters only accepts null");
            }
        }
    }

    /** Returns the Logger for this Bean */
    @Override
    public final Logger log() {
        return metaType.logger;
    }

    @Override
    public final Iterable<Object> resolvePath(final BeanPath path,
            final boolean failOnIncompatbileProperty) {
        Objects.requireNonNull(path, "path");
        final List<Object> values = new ArrayList<>();
        values.add(this);
        BeanPath curPath = path;
        while (true) {
            final Object[] keyMatcher = curPath.keyMatcher;
            final BeanPath next = curPath.next;
            final Object[] objects = values.toArray();
            values.clear();
            for (final Object obj : objects) {
                if (obj instanceof _Bean) {
                    final _Bean bean = (_Bean) obj;
                    for (final IProperty<?, ?> p : curPath.propertyMatcher
                            .listProperty(bean)) {
                        if (failOnIncompatbileProperty) {
                            bean.readProperty(p, keyMatcher, values);
                        } else {
                            try {
                                bean.readProperty(p, keyMatcher, values);
                            } catch (final RuntimeException e) {
                                // NOP
                            }
                        }
                    }
                }
            }
            if (values.isEmpty() || (next == null)) {
                return values;
            }
            curPath = next;
        }
    }

    /** Reads the value(s) of this Property, and add them to values, if they match. */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Override
    public void readProperty(final IProperty<?, ?> p,
            final Object[] keyMatcher, final List<Object> values) {
        final Object current = ((Property) p).getObject(this);
        // Normal properties don't have a key/index, so any matcher would cause a "fail"
        // This condition cannot be "moved up", because this method will be overwritten
        if (keyMatcher == null) {
            values.add(current);
        }
    }

    /** Resolves a "simple" path to a value (including null, if the value, or any link, is null) */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    @Override
    public final Object resolvePath(final Property... props) {
        Objects.requireNonNull(props, "props");
        Object result = this;
        for (final Property property : props) {
            result = property.getObject(result);
            if (result == null) {
                break;
            }
        }
        return result;
    }

    /** Called after a change of parent/key. */
    protected void onParentBeanAndKeyChange() {
        // NOP
    }
}
