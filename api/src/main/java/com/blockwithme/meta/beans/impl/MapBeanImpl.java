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

import java.util.AbstractCollection;
import java.util.AbstractSet;
import java.util.Arrays;
import java.util.Collection;
import java.util.Comparator;
import java.util.ConcurrentModificationException;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.Set;

import com.blockwithme.meta.IProperty;
import com.blockwithme.meta.JavaMeta;
import com.blockwithme.meta.Property;
import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans.Bean;
import com.blockwithme.meta.beans.BeanVisitable;
import com.blockwithme.meta.beans.BeanVisitor;
import com.blockwithme.meta.beans.ObjectObjectMapInterceptor;
import com.blockwithme.meta.beans._Bean;
import com.blockwithme.meta.beans._MapBean;
import com.blockwithme.util.base.SystemUtils;
import com.blockwithme.util.shared.MurmurHash;

class MapBeanEntry<K, V> implements Map.Entry<K, V>, BeanVisitable {
    private final K key;
    private final V value;
    private final MapBeanImpl<K, V> map;

    public MapBeanEntry(final K key, final V value, final MapBeanImpl<K, V> map) {
        this.key = key;
        this.value = value;
        this.map = map;
    }

    @Override
    public K getKey() {
        return key;
    }

    @Override
    public V getValue() {
        return value;
    }

    @Override
    public V setValue(final V newValue) {
        return map.put(key, newValue);
    }

    @Override
    public String toString() {
        return "{\"key\":" + key + ",\"value\":" + value + "}";
    }

    @Override
    public void accept(final BeanVisitor visitor) {
        if (visitor.startVisitNonBean(this)) {
            visitor.visitNonBeanProperty("key", key);
            visitor.visitNonBeanProperty("value", value);
        }
        visitor.endVisitNonBean(this);
    }
}

/**
 * The implementation of _MapBean<K, V>.
 *
 * @author monster
 */
public class MapBeanImpl<K, V> extends _BeanImpl implements _MapBean<K, V> {

    /** Iterator over both key and values, but returns only the ones that are _Beans. */
    private final class BeanMapIterator implements Iterator<_Bean> {

        /** Entry-Set iterator. */
        private final Iterator<java.util.Map.Entry<K, V>> iter = entrySet()
                .iterator();

        /** Next key, if it's a Bean. */
        private _Bean nextKey;

        /** Next value, if it's a Bean. */
        private _Bean nextValue;

        /** Tries to find some _Beans to return. */
        private void findNext() {
            while (!hasNext() && iter.hasNext()) {
                final java.util.Map.Entry<K, V> e = iter.next();
                final K key = e.getKey();
                if (key instanceof _Bean) {
                    nextKey = (_Bean) key;
                } else {
                    nextKey = null;
                }
                final V value = e.getValue();
                if (value instanceof _Bean) {
                    nextValue = (_Bean) value;
                } else {
                    nextValue = null;
                }
            }
        }

        public BeanMapIterator() {
            findNext();
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#hasNext()
         */
        @Override
        public boolean hasNext() {
            return (nextKey != null) || (nextValue != null);
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#next()
         */
        @Override
        public _Bean next() {
            if (nextKey != null) {
                final _Bean result = nextKey;
                nextKey = null;
                if (nextValue == null) {
                    findNext();
                }
                return result;
            }
            if (nextValue != null) {
                final _Bean result = nextValue;
                nextValue = null;
                findNext();
                return result;
            }
            return null;
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#remove()
         */
        @Override
        public void remove() {
            throw new UnsupportedOperationException();
        }
    }

    /** Comparable Entry Comparator. */
    @SuppressWarnings("rawtypes")
    private static final Comparator<Map.Entry> COMPARABLE_ENTRY_CMP = new Comparator<Map.Entry>() {
        @SuppressWarnings("unchecked")
        @Override
        public int compare(final Map.Entry o1, final Map.Entry o2) {
            return ((Comparable) o1.getKey()).compareTo(o2.getKey());
        }
    };

    /** Non-comparable Entry Comparator. */
    @SuppressWarnings("rawtypes")
    private static final Comparator<Map.Entry> NON_COMPARABLE_ENTRY_CMP = new Comparator<Map.Entry>() {
        @Override
        public int compare(final Map.Entry o1, final Map.Entry o2) {
            return NON_COMPARABLE_CMP.compare(o1.getKey(), o2.getKey());
        }
    };

    /** Minimum size */
    private static final int MIN_SIZE = 8;

    /** The Type of the keys. */
    private final Type<K> keyType;

    /** The Type of the values. */
    private final Type<V> valueType;

    /** The collection size */
    private int size;

    /** The keys */
    private K[] keys;

    /** The values */
    private V[] values;

    /** Lazy created key set. */
    private Set<K> keySet;

    /** Lazy created value Collection. */
    private Collection<V> valuesCollection;

    /** Lazy created entry set. */
    private Set<Map.Entry<K, V>> entrySet;

    /** Helper field for immutable maps. */
    private transient int lastPutIndex;

    /** Returns the Map interceptor. */
    @SuppressWarnings("unchecked")
    private ObjectObjectMapInterceptor<K, V> interceptor() {
        return (ObjectObjectMapInterceptor<K, V>) interceptor;
    }

    /** Returns a new K array of given size. */
    private K[] newKeysArray(final int length) {
        return keyType.newArray(length);
    }

    /** Returns a new V array of given size. */
    private V[] newValuesArray(final int length) {
        return valueType.newArray(length);
    }

    /** Increases the array size. */
    private void ensureCapacityInternalAndClear(final int minCapacity) {
        final int oldCapacity = keys.length;
        // This detaches the current content, so it can be re-added later.
        clear();
        // ensureSelectionCapacity() makes sure that the value of minCapacity is "reasonable"
        // We must account for the fact that each "index" holds *two* values (key and value)
        ensureSelectionCapacity(minCapacity * 2);
        int newCapacity;
        if (minCapacity < MIN_SIZE) {
            newCapacity = MIN_SIZE;
        } else {
            newCapacity = oldCapacity;
            if (newCapacity < MIN_SIZE) {
                newCapacity = MIN_SIZE;
            }
            while (newCapacity < minCapacity) {
                newCapacity *= 2;
            }
        }
        keys = newKeysArray(newCapacity);
        values = newValuesArray(newCapacity);
    }

    /**
     * Returns a non-negative value, if the key is at the given position.
     * Otherwise return -theoretical_position-1
     */
    private int indexOf(final Object key) {
        if (key == null) {
            throw new NullPointerException("key");
        }
        final K[] array = keys;
        final int length = array.length;
        final ObjectObjectMapInterceptor<K, V> oomi = interceptor();
        if (length == 0) {
            return -1;
        }
        final int hash = MurmurHash.hash32(key.hashCode()) & Integer.MAX_VALUE;
        final int pos = hash % length;
        if (key.equals(oomi.getKeyAtIndex(this, pos, array[pos]))) {
            return pos;
        }
        int nextTry = (pos + length - 1) % length;
        if (key.equals(oomi.getKeyAtIndex(this, nextTry, array[nextTry]))) {
            return nextTry;
        }
        nextTry = (pos + 1) % length;
        if (key.equals(oomi.getKeyAtIndex(this, nextTry, array[nextTry]))) {
            return nextTry;
        }
        return -pos - 1;
    }

    /**
     * @param metaType
     * @param theKeyType
     * @param theValueType
     */
    public MapBeanImpl(final Type<?> metaType, final Type<K> theKeyType,
            final Type<V> theValueType) {
        super(metaType);
        interceptor = DefaultObjectObjectMapInterceptor.INSTANCE;
        keyType = Objects.requireNonNull(theKeyType, "theKeyType");
        valueType = Objects.requireNonNull(theValueType, "theValueType");
        keys = theKeyType.empty;
        values = theValueType.empty;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.beans.MapBean#getKeyType()
     */
    @Override
    public Type<K> getKeyType() {
        return keyType;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.beans.MapBean#getValueType()
     */
    @Override
    public Type<V> getValueType() {
        return valueType;
    }

    /* (non-Javadoc)
     * @see java.util.Map#size()
     */
    @Override
    public int size() {
        return size;
    }

    /* (non-Javadoc)
     * @see java.util.Map#isEmpty()
     */
    @Override
    public boolean isEmpty() {
        return (size == 0);
    }

    /* (non-Javadoc)
     * @see java.util.Map#containsValue(java.lang.Object)
     */
    @Override
    public boolean containsValue(final Object value) {
        final int length = keys.length;
        final ObjectObjectMapInterceptor<K, V> oomi = interceptor();
        if (value == null) {
            for (int i = 0; i < length; i++) {
                if (oomi.getKeyAtIndex(this, i, keys[i]) != null) {
                    if (oomi.getValueAtIndex(this, i, values[i]) == null) {
                        return true;
                    }
                }
            }
        } else {
            for (int i = 0; i < length; i++) {
                if (oomi.getKeyAtIndex(this, i, keys[i]) != null) {
                    if (value.equals(oomi.getValueAtIndex(this, i, values[i]))) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /* (non-Javadoc)
     * @see java.util.Map#containsKey(java.lang.Object)
     */
    @Override
    public boolean containsKey(final Object key) {
        return (key == null) ? false : indexOf(key) >= 0;
    }

    /* (non-Javadoc)
     * @see java.util.Map#get(java.lang.Object)
     */
    @Override
    public V get(final Object key) {
        if (key == null) {
            return null;
        }
        final int index = indexOf(key);
        return (index >= 0) ? interceptor().getValueAtIndex(this, index,
                values[index]) : null;
    }

    /* (non-Javadoc)
     * @see java.util.Map#putAll(java.util.Map)
     */
    @Override
    public void putAll(final Map<? extends K, ? extends V> m) {
        for (final Map.Entry<? extends K, ? extends V> e : m.entrySet()) {
            put(e.getKey(), e.getValue());
        }
    }

    /* (non-Javadoc)
     * @see java.util.Map#clear()
     */
    @Override
    public void clear() {
        if (isImmutable()) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        final int length = size;
        if (length > 0) {
            final ObjectObjectMapInterceptor<K, V> oomi = interceptor();
            oomi.clear(this);
            if (SystemUtils.isAssignableFrom(Bean.class, getKeyType().type)) {
                for (final K k : keys) {
                    if (k instanceof _Bean) {
                        ((_Bean) k).setParentBeanAndKey(null, null);
                    }
                }
            }
            if (SystemUtils.isAssignableFrom(Bean.class, getValueType().type)) {
                for (final V v : values) {
                    if (v instanceof _Bean) {
                        ((_Bean) v).setParentBeanAndKey(null, null);
                    }
                }
            }
            size = 0;
            keys = getKeyType().empty;
            values = getValueType().empty;
            clearSelectionArray();
            clearSelection(false, false);
            incrementChangeCounter();
        }
    }

    /* (non-Javadoc)
     * @see java.util.Map#remove(java.lang.Object)
     */
    @SuppressWarnings("unchecked")
    @Override
    public V remove(final Object key) {
        if (isImmutable()) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        final int index = indexOf(key);
        if (index >= 0) {
            final ObjectObjectMapInterceptor<K, V> oomi = interceptor();
            final V result = oomi.getValueAtIndex(this, index, values[index]);
            keys[index] = oomi.setKeyAtIndex(this, index, (K) key, null);
            values[index] = oomi.setValueAtIndex(this, (K) key, index, result,
                    null);
            size--;
            return result;
        }
        return null;
    }

    private V put2(final ObjectObjectMapInterceptor<K, V> oomi, final K key,
            final int index, final V value) {
        // We don't bother checking if it's "off by 1", and the real index is free.
        final V result = oomi.getValueAtIndex(this, index, values[index]);
        values[index] = oomi.setValueAtIndex(this, key, index, result, value);
        lastPutIndex = index;
        return result;
    }

    /* (non-Javadoc)
     * @see java.util.Map#put(java.lang.Object, java.lang.Object)
     */
    @Override
    public V put(final K key, final V value) {
        if (key == null) {
            throw new NullPointerException("key");
        }
        if (isImmutable()) {
            throw new UnsupportedOperationException(this + " is immutable!");
        }
        final K[] array = keys;
        final int length = array.length;
        if (length > 0) {
            final ObjectObjectMapInterceptor<K, V> oomi = interceptor();
            final int hash = MurmurHash.hash32(key.hashCode())
                    & Integer.MAX_VALUE;
            final int pos = hash % length;
            final K posKey = oomi.getKeyAtIndex(this, pos, array[pos]);
            if (key.equals(posKey)) {
                return put2(oomi, key, pos, value);
            }
            final int prevPos = (pos + length - 1) % length;
            final K posPrevKey = oomi.getKeyAtIndex(this, prevPos,
                    array[prevPos]);
            if (key.equals(posPrevKey)) {
                return put2(oomi, key, prevPos, value);
            }
            final int nextPos = (pos + 1) % length;
            final K posNextKey = oomi.getKeyAtIndex(this, nextPos,
                    array[nextPos]);
            if (key.equals(posNextKey)) {
                return put2(oomi, key, nextPos, value);
            }
            // New key ...
            size++;
            if (posKey == null) {
                array[pos] = oomi.setKeyAtIndex(this, pos, null, key);
                return put2(oomi, key, pos, value);
            }
            if (posPrevKey == null) {
                array[prevPos] = oomi.setKeyAtIndex(this, prevPos, null, key);
                return put2(oomi, key, prevPos, value);
            }
            if (posNextKey == null) {
                array[nextPos] = oomi.setKeyAtIndex(this, nextPos, null, key);
                return put2(oomi, key, nextPos, value);
            }
        }
        // We need to grow. And we assume it will only happen once, so that recursion is OK.
        // Since both keys and values array are replaced, we do not need to clone them first.
        final K[] oldKeyes = keys;
        final V[] oldValues = values;
        ensureCapacityInternalAndClear((length == 0) ? MIN_SIZE : length * 2);
        for (int i = 0; i < length; i++) {
            if (oldKeyes[i] != null) {
                put(oldKeyes[i], oldValues[i]);
            }
        }
        put(key, value);
        return null;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.ContentOwner#getContent()
     */
    @Override
    public Map.Entry<K, V>[] getContent() {
        @SuppressWarnings("unchecked")
        final Map.Entry<K, V>[] result = entrySet()
                .toArray(new Map.Entry[size]);
        if (Comparable.class.isAssignableFrom(getKeyType().type)) {
            Arrays.sort(result, COMPARABLE_ENTRY_CMP);
        } else {
            Arrays.sort(result, NON_COMPARABLE_ENTRY_CMP);
        }
        return result;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.beans.Bean#getDelegate()
     */
    @SuppressWarnings("unchecked")
    @Override
    public final MapBeanImpl<K, V> getDelegate() {
        return (MapBeanImpl<K, V>) super.getDelegate();
    }

    /* (non-Javadoc)
     * @see java.util.Map#keySet()
     */
    @Override
    public Set<K> keySet() {
        if (keySet == null) {
            keySet = new AbstractSet<K>() {
                @Override
                public Iterator<K> iterator() {
                    return new Iterator<K>() {
                        final ObjectObjectMapInterceptor<K, V> oomi = interceptor();
                        int cursor;     // index of next element to return
                        K lastRet;      // last element returned; null if no such
                        K next;

                        @Override
                        public boolean hasNext() {
                            if (next == null) {
                                final K[] array = keys;
                                final int length = array.length;
                                if (cursor < length) {
                                    if (cursor >= length)
                                        throw new ConcurrentModificationException();
                                    while ((cursor < length) && (next == null)) {
                                        next = oomi.getKeyAtIndex(
                                                MapBeanImpl.this, cursor,
                                                array[cursor]);
                                        cursor++;
                                    }
                                }
                                return (next != null);
                            }
                            return true;
                        }

                        @Override
                        public K next() {
                            hasNext();
                            if (next == null)
                                throw new NoSuchElementException();
                            final K result = next;
                            next = null;
                            lastRet = result;
                            return result;
                        }

                        @Override
                        public void remove() {
                            if (lastRet == null)
                                throw new IllegalStateException();

                            try {
                                MapBeanImpl.this.remove(lastRet);
                                lastRet = null;
                            } catch (final IndexOutOfBoundsException ex) {
                                throw new ConcurrentModificationException();
                            }
                        }
                    };
                }

                @Override
                public int size() {
                    return size;
                }
            };
        }
        return keySet;
    }

    /* (non-Javadoc)
     * @see java.util.Map#values()
     */
    @Override
    public Collection<V> values() {
        if (valuesCollection == null) {
            valuesCollection = new AbstractCollection<V>() {
                @Override
                public Iterator<V> iterator() {
                    return new Iterator<V>() {
                        final Iterator<K> keyIter = keySet().iterator();

                        @Override
                        public boolean hasNext() {
                            return keyIter.hasNext();
                        }

                        @Override
                        public V next() {
                            return get(keyIter.next());
                        }

                        @Override
                        public void remove() {
                            keyIter.remove();
                        }
                    };
                }

                @Override
                public int size() {
                    return size;
                }
            };
        }
        return valuesCollection;
    }

    /* (non-Javadoc)
     * @see java.util.Map#entrySet()
     */
    @Override
    public Set<Map.Entry<K, V>> entrySet() {
        if (entrySet == null) {
            entrySet = new AbstractSet<Map.Entry<K, V>>() {
                @Override
                public Iterator<Map.Entry<K, V>> iterator() {
                    return new Iterator<Map.Entry<K, V>>() {
                        private JacksonSerializer js;
                        final Iterator<K> keyIter = keySet().iterator();

                        @Override
                        public boolean hasNext() {
                            return keyIter.hasNext();
                        }

                        @Override
                        public Map.Entry<K, V> next() {
                            final K key = keyIter.next();
                            final V value = get(key);
                            return new MapBeanEntry<K, V>(key, value,
                                    MapBeanImpl.this);
                        }

                        @Override
                        public void remove() {
                            keyIter.remove();
                        }
                    };
                }

                @Override
                public int size() {
                    return size;
                }
            };
        }
        return entrySet;
    }

    /** Make a new instance of the same type as self. */
    @Override
    protected _BeanImpl newInstance() {
        return new MapBeanImpl<K, V>(metaType, keyType, valueType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.beans.Bean#copy()
     */
    @SuppressWarnings("unchecked")
    @Override
    public final MapBeanImpl<K, V> copy() {
        return (MapBeanImpl<K, V>) doCopy();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.beans.Bean#snapshot()
     */
    @SuppressWarnings("unchecked")
    @Override
    public final MapBeanImpl<K, V> snapshot() {
        return (MapBeanImpl<K, V>) doSnapshot();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.beans.Bean#wrapper()
     */
    @Override
    public final MapBeanImpl<K, V> wrapper() {
        throw new UnsupportedOperationException(
                "Wrapping doesn't work fo colledction because insert/remove changes the structure");
    }

    /** Reads the value(s) of this Property, and add them to values, if they match. */
    @Override
    public void readProperty(final IProperty<?, ?> prop,
            final Object[] keyMatcher, final List<Object> values) {
        if (prop == JavaMeta.MAP_CONTENT_PROP) {
            if (keyMatcher == null) {
                values.addAll(values());
            } else {
                for (final Object key : keyMatcher) {
                    values.add(get(key));
                }
            }
        } else {
            super.readProperty(prop, keyMatcher, values);
        }
    }

    /** Allows collections to perform special copy implementations. */
    @Override
    @SuppressWarnings({ "unchecked", "rawtypes" })
    protected void copyValue(final Property p, final _BeanImpl _other,
            final boolean immutably) {
        final MapBeanImpl<K, V> other = (MapBeanImpl<K, V>) _other;
        if (p == JavaMeta.MAP_CONTENT_PROP) {
            ensureCapacityInternalAndClear(other.keys.length);
            if (immutably) {
                if (other.keyType.bean && other.valueType.bean) {
                    for (final Entry<K, V> e : other.entrySet()) {
                        final _BeanImpl k = (_BeanImpl) e.getKey();
                        final _BeanImpl kCopy = (k == null) ? null : k
                                .doSnapshot();
                        final _BeanImpl v = (_BeanImpl) e.getValue();
                        final _BeanImpl vCopy = (v == null) ? null : v
                                .doSnapshot();
                        put((K) kCopy, (V) vCopy);
                        if (kCopy != null) {
                            kCopy.setParentBeanAndKey(this, lastPutIndex);
                        }
                        if (vCopy != null) {
                            vCopy.setParentBeanAndKey(this, kCopy);
                        }
                    }
                } else if (other.keyType.bean) {
                    for (final Entry<K, V> e : other.entrySet()) {
                        final _BeanImpl k = (_BeanImpl) e.getKey();
                        final _BeanImpl kCopy = (k == null) ? null : k
                                .doSnapshot();
                        put((K) kCopy, e.getValue());
                        if (kCopy != null) {
                            kCopy.setParentBeanAndKey(this, lastPutIndex);
                        }
                    }
                } else if (other.valueType.bean) {
                    for (final Entry<K, V> e : other.entrySet()) {
                        final K k = e.getKey();
                        final _BeanImpl v = (_BeanImpl) e.getValue();
                        final _BeanImpl vCopy = (v == null) ? null : v
                                .doSnapshot();
                        put(k, (V) vCopy);
                        if (vCopy != null) {
                            vCopy.setParentBeanAndKey(this, k);
                        }
                    }
                } else {
                    for (final Entry<K, V> e : other.entrySet()) {
                        put(e.getKey(), e.getValue());
                    }
                }
            } else {
                if (other.keyType.bean && other.valueType.bean) {
                    for (final Entry<K, V> e : other.entrySet()) {
                        final _BeanImpl k = (_BeanImpl) e.getKey();
                        final _BeanImpl kCopy = (k == null) ? null : k.doCopy();
                        final _BeanImpl v = (_BeanImpl) e.getValue();
                        final _BeanImpl vCopy = (v == null) ? null : v.doCopy();
                        put((K) kCopy, (V) vCopy);
                    }
                } else if (other.keyType.bean) {
                    for (final Entry<K, V> e : other.entrySet()) {
                        final _BeanImpl k = (_BeanImpl) e.getKey();
                        final _BeanImpl kCopy = (k == null) ? null : k.doCopy();
                        put((K) kCopy, e.getValue());
                    }
                } else if (other.valueType.bean) {
                    for (final Entry<K, V> e : other.entrySet()) {
                        final _BeanImpl v = (_BeanImpl) e.getValue();
                        final _BeanImpl vCopy = (v == null) ? null : v.doCopy();
                        put(e.getKey(), (V) vCopy);
                    }
                } else {
                    for (final Entry<K, V> e : other.entrySet()) {
                        put(e.getKey(), e.getValue());
                    }
                }
            }
        } else {
            p.copyValue(_other, this);
        }
    }

    /** Returns an Iterable<_Bean>, over the property values */
    @Override
    protected final Iterable<_Bean> getBeanIterator() {
        if (keyType.bean || valueType.bean) {
            return new SubBeanIterator(new BeanMapIterator());
        }
        return super.getBeanIterator();
    }
}
