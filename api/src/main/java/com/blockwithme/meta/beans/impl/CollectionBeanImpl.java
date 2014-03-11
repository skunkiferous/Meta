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
import java.util.ConcurrentModificationException;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.NoSuchElementException;
import java.util.Objects;

import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans._Bean;

/**
 * Base class for a Bean that contains a Collection of other Objects.
 *
 * @author monster
 */
public abstract class CollectionBeanImpl<E> extends _BeanImpl implements
        List<E> {

    /** An Iterable<_Bean>, over the Collection values */
    private class BeanCollectionIterator implements Iterable<_Bean>,
            Iterator<_Bean> {

        /** The next bean */
        private _Bean next;

        /** Next property index to check. */
        private int nextIndex;

        private void findNext() {
            while (nextIndex < size) {
                final Object value = data[nextIndex];
                if (value instanceof _Bean) {
                    next = (_Bean) value;
                    break;
                }
                nextIndex++;
            }
            next = null;
        }

        /** Constructor */
        public BeanCollectionIterator() {
            findNext();
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
            return next != null;
        }

        /* (non-Javadoc)
         * @see java.util.Iterator#next()
         */
        @Override
        public final _Bean next() {
            if (hasNext()) {
                final _Bean result = next;
                findNext();
                return result;
            }
            throw new NoSuchElementException();
        }

    }

    /**
     * An optimized version of AbstractList.Itr
     */
    private class Itr implements Iterator<E> {
        int cursor;       // index of next element to return
        int lastRet = -1; // index of last element returned; -1 if no such

        @Override
        public boolean hasNext() {
            return cursor != size;
        }

        @Override
        @SuppressWarnings("unchecked")
        public E next() {
            final int i = cursor;
            if (i >= size)
                throw new NoSuchElementException();
            final Object[] elementData = data;
            if (i >= elementData.length)
                throw new ConcurrentModificationException();
            cursor = i + 1;
            return (E) elementData[lastRet = i];
        }

        @Override
        public void remove() {
            if (lastRet < 0)
                throw new IllegalStateException();

            try {
                CollectionBeanImpl.this.remove(lastRet);
                cursor = lastRet;
                lastRet = -1;
            } catch (final IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }
    }

    /**
     * An optimized version of AbstractList.ListItr
     */
    private class ListItr extends Itr implements ListIterator<E> {
        ListItr(final int index) {
            super();
            cursor = index;
        }

        @Override
        public boolean hasPrevious() {
            return cursor != 0;
        }

        @Override
        public int nextIndex() {
            return cursor;
        }

        @Override
        public int previousIndex() {
            return cursor - 1;
        }

        @Override
        @SuppressWarnings("unchecked")
        public E previous() {
            final int i = cursor - 1;
            if (i < 0)
                throw new NoSuchElementException();
            final Object[] elementData = data;
            if (i >= elementData.length)
                throw new ConcurrentModificationException();
            cursor = i;
            return (E) elementData[lastRet = i];
        }

        @Override
        public void set(final E e) {
            if (lastRet < 0)
                throw new IllegalStateException();

            try {
                CollectionBeanImpl.this.set(lastRet, e);
            } catch (final IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }

        @Override
        public void add(final E e) {
            try {
                final int i = cursor;
                CollectionBeanImpl.this.add(i, e);
                cursor = i + 1;
                lastRet = -1;
            } catch (final IndexOutOfBoundsException ex) {
                throw new ConcurrentModificationException();
            }
        }
    }

    /** The CollectionBeanConfig */
    private final CollectionBeanConfig config;

    /** The collection size */
    private int size;

    /** The Collection */
    private E[] data;

    /** Returns a new E array of given size. */
    @SuppressWarnings("unchecked")
    private E[] newArray(final int length) {
        return (E[]) getMetaType().newArray(length);
    }

    /**
     * Checks if the given index is in range.
     */
    private void rangeCheck(final int index) {
        if (index >= size)
            throw new IndexOutOfBoundsException("Index: " + index);
    }

    private void ensureCapacityInternal(final int minCapacity) {
        final E[] array = data;
        final int oldCapacity = (array == null) ? 0 : array.length;
        if (minCapacity > oldCapacity) {
            final E[] newArray = newArray(minCapacity);
            if (array != null) {
                System.arraycopy(array, 0, newArray, 0, oldCapacity);
            }
            data = newArray;
        }
    }

    /**
     * @param metaType
     */
    @SuppressWarnings("unchecked")
    public CollectionBeanImpl(final Type<?> metaType,
            final CollectionBeanConfig config) {
        super(metaType);
        Objects.requireNonNull(config, "config").validate(metaType);
        this.config = config;
        final int fixedSize = config.getFixedSize();
        if (fixedSize != -1) {
            size = fixedSize;
            data = newArray(fixedSize);
        } else {
            data = (E[]) metaType.empty;
        }
    }

    /** Returns an Iterable<_Bean>, over the property values */
    @Override
    protected final Iterable<_Bean> getBeanIterator() {
        return new BeanCollectionIterator();
    }

    /** Returns the number of possible selections. */
    @Override
    protected final int getSelectionCount() {
        return size;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#size()
     */
    @Override
    public final int size() {
        return size;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#isEmpty()
     */
    @Override
    public final boolean isEmpty() {
        return size == 0;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#contains(java.lang.Object)
     */
    @Override
    public final boolean contains(final Object o) {
        return indexOf(o) != -1;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#clear()
     */
    @SuppressWarnings("unchecked")
    @Override
    public final void clear() {
        if (config.getFixedSize() != -1) {
            throw new UnsupportedOperationException("Fixed-size!");
        }
        size = 0;
        data = (E[]) getMetaType().empty;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#containsAll(java.util.Collection)
     */
    @Override
    public final boolean containsAll(final Collection<?> c) {
        for (final Object e : c)
            if (!contains(e))
                return false;
        return true;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#toArray()
     */
    @Override
    public final Object[] toArray() {
        return toArray(new Object[size]);
    }

    /* (non-Javadoc)
     * @see java.util.Collection#addAll(java.util.Collection)
     */
    @Override
    public final boolean addAll(final Collection<? extends E> c) {
        boolean modified = false;
        for (final E e : c)
            if (add(e))
                modified = true;
        return modified;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#removeAll(java.util.Collection)
     */
    @Override
    public final boolean removeAll(final Collection<?> c) {
        boolean modified = false;
        for (final Object e : c)
            if (remove(e))
                modified = true;
        return modified;
    }

    /* (non-Javadoc)
     * @see java.util.List#indexOf(java.lang.Object)
     */
    @Override
    public final int indexOf(final Object o) {
        final int length = size;
        final E[] array = data;
        if (o == null) {
            for (int i = 0; i < length; i++) {
                if (array[i] == null) {
                    return i;
                }
            }
        } else {
            for (int i = 0; i < length; i++) {
                if (o.equals(array[i])) {
                    return i;
                }
            }
        }
        return -1;
    }

    /* (non-Javadoc)
     * @see java.util.List#lastIndexOf(java.lang.Object)
     */
    @Override
    public final int lastIndexOf(final Object o) {
        final int length = size;
        final E[] array = data;
        if (o == null) {
            for (int i = length - 1; i >= 0; i--) {
                if (array[i] == null) {
                    return i;
                }
            }
        } else {
            for (int i = length - 1; i >= 0; i--) {
                if (o.equals(array[i])) {
                    return i;
                }
            }
        }
        return -1;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#retainAll(java.util.Collection)
     */
    @Override
    public final boolean retainAll(final Collection<?> c) {
        boolean modified = false;
        final E[] array = data;
        for (int i = 0; i < size; i++) {
            final E value = array[i];
            if (!c.contains(value)) {
                remove(i--);
                modified = true;
            }
        }
        return modified;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#remove(java.lang.Object)
     */
    @Override
    public final boolean remove(final Object o) {
        final int index = indexOf(o);
        if (index == -1) {
            return false;
        }
        remove(index);
        return true;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#toArray(java.lang.Object[])
     */
    @SuppressWarnings("unchecked")
    @Override
    public final <T> T[] toArray(final T[] a) {
        final T[] result = a.length >= size ? a : (T[]) java.lang.reflect.Array
                .newInstance(a.getClass().getComponentType(), size);
        System.arraycopy(data, 0, result, 0, size);
        return result;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#iterator()
     */
    @Override
    public final Iterator<E> iterator() {
        return new Itr();
    }

    /* (non-Javadoc)
     * @see java.util.List#listIterator(int)
     */
    @Override
    public final ListIterator<E> listIterator(final int index) {
        if (index < 0 || index > size)
            throw new IndexOutOfBoundsException("Index: " + index);
        return new ListItr(index);
    }

    /* (non-Javadoc)
     * @see java.util.List#listIterator()
     */
    @Override
    public final ListIterator<E> listIterator() {
        return new ListItr(0);
    }

    /* (non-Javadoc)
     * @see java.util.List#get(int)
     */
    @Override
    public final E get(final int index) {
        rangeCheck(index);
        return data[index];
    }

    /* (non-Javadoc)
     * @see java.util.List#set(int,java.lang.Object)
     */
    @Override
    public final E set(final int index, final E element) {
        rangeCheck(index);
        if ((element == null) && !config.isNullAllowed()) {
            throw new IllegalArgumentException("Null not allowed!");
        }
        if (config.isSet()) {
            throw new IllegalArgumentException(
                    "set(int,E) not allowed for Set!");
        }
        final E[] array = data;
        final E oldValue = array[index];
        array[index] = element;
        return oldValue;
    }

    /* (non-Javadoc)
     * @see java.util.List#add(int,java.lang.Object)
     */
    private boolean add2(final int index, final E element) {
        if (index > size || index < 0)
            throw new IndexOutOfBoundsException("Index: " + index);
        if (config.getFixedSize() != -1) {
            throw new UnsupportedOperationException("Fixed-size!");
        }
        if ((element == null) && !config.isNullAllowed()) {
            throw new IllegalArgumentException("Null not allowed!");
        }
        ensureCapacityInternal(size + 1);
        final E[] array = data;
        if (index == size) {
            if (config.isSet()) {
                if (!contains(element)) {
                    if (config.isOrderedSet()) {
                        array[index] = element;
                        size++;
                    } else {
                        final Comparable cmp = (Comparable) element;
                        boolean added = false;
                        for (int i = 0; !added && (i < array.length); i++) {
                            if (cmp.compareTo(array[i]) < 0) {
                                System.arraycopy(array, i, array, i + 1, size
                                        - i);
                                array[i] = element;
                                added = true;
                            }
                        }
                        if (!added) {
                            array[index] = element;
                        }
                        size++;
                    }
                }
            } else {
                array[index] = element;
                size++;
            }
        } else {
            if (config.isSet()) {
                throw new IllegalArgumentException(
                        "add(int,E) not allowed for Set!");
            }
            System.arraycopy(array, index, array, index + 1, size - index);
            array[index] = element;
            size++;
        }
        return true;
    }

    /* (non-Javadoc)
     * @see java.util.Collection#add(java.lang.Object)
     */
    @Override
    public final boolean add(final E element) {
        return add2(size, element);
    }

    /* (non-Javadoc)
     * @see java.util.List#add(int,java.lang.Object)
     */
    @Override
    public final void add(final int index, final E element) {
        add2(index, element);
    }

    /* (non-Javadoc)
     * @see java.util.List#remove(int)
     */
    @Override
    public final E remove(final int index) {
        rangeCheck(index);
        if (config.getFixedSize() != -1) {
            throw new UnsupportedOperationException("Fixed-size!");
        }
        final E[] array = data;
        final E result = array[index];
        final int length = size - index - 1;
        System.arraycopy(array, index + 1, array, index, length);
        size--;
        array[size] = null;
        return result;
    }

    /* (non-Javadoc)
     * @see java.util.List#addAll(int, java.util.Collection)
     */
    @Override
    public final boolean addAll(final int index, final Collection<? extends E> c) {
        int i = index;
        for (final E e : c)
            if (add2(i, e)) {
                i++;
            }
        return i != index;
    }

    /* (non-Javadoc)
     * @see java.util.List#subList(int, int)
     */
    @Override
    public final List<E> subList(final int fromIndex, final int toIndex) {
        throw new UnsupportedOperationException("TODO!");
    }

}
