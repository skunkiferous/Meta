/*
 * Copyright (C) 2013 Sebastien Diot.
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
package com.blockwithme.properties.impl;

import java.util.Comparator;
import java.util.Iterator;
import java.util.TreeMap;

import com.blockwithme.properties.Properties;

/**
 * Properties default implementation.
 *
 * @author monster
 */
public class PropertiesImpl<TIME extends Comparable<TIME>> extends
        PropertiesBase<TIME> {

    /** Comparator that compare integers as numbers, and all non-integers as smaller then integers. */
    private static final Comparator<String> KEY_CMP = new Comparator<String>() {

        private Long toLong(final String str) {
            try {
                return Long.parseLong(str, 10);
            } catch (final NumberFormatException e) {
                return null;
            }
        }

        @Override
        public int compare(final String o1, final String o2) {
            final Long l1 = toLong(o1);
            final Long l2 = toLong(o2);
            if (l1 == null) {
                if (l2 == null) {
                    return o1.compareTo(o2);
                }
                return -1;
            }
            if (l2 != null) {
                return l1.compareTo(l2);
            }
            return -1;
        }
    };

    /** All the own properties. */
    private final TreeMap<String, Object> properties = new TreeMap<>(KEY_CMP);

    /** The Change Tracker */
    private final ChangeTracker<TIME> changeTracker;

    /**
     * @param parent
     * @param localKey
     */
    public PropertiesImpl(final PropertiesImpl<TIME> parent,
            final String localKey) {
        this(parent, localKey, (parent == null) ? null : parent.changeTracker);
    }

    /**
     * @param parent
     * @param localKey
     */
    public PropertiesImpl(final PropertiesBase<TIME> parent,
            final String localKey, final ChangeTracker<TIME> changeTracker) {
        super(parent, localKey);
        setLocalProperty("globalKey", globalKey(), null);
        setLocalProperty("localKey", localKey(), null);
        // changeTracker set on purpose *after* setting the built-in properties.
        this.changeTracker = changeTracker;
        if (changeTracker != null) {
            // null/null/null means "created"
            changeTracker.onChange(this, null, null, null);
        }
    }

    /** Returns true, if this is a built-in property. */
    @Override
    protected boolean builtIn(final String localKey) {
        return super.builtIn(localKey) || "globalKey".equals(localKey)
                || "localKey".equals(localKey);
    }

    /**
     * Returns the property value, if any. Null if absent.
     */
    @Override
    protected Object findLocalRaw(final String localKey) {
        return properties.get(localKey);
    }

    /* (non-Javadoc)
     * @see java.lang.Iterable#iterator()
     */
    @Override
    public Iterator<String> iterator() {
        return properties.keySet().iterator();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.impl.PropertiesBase#setLocalProperty(java.lang.String, java.lang.Object)
     */
    @Override
    protected final void setLocalProperty(final String localKey,
            final Object value, final TIME when) {
        checkLocalKey(localKey, "localKey", localKey);
        if (when != null) {
            root().onFutureChange(this, localKey, value, when);
        } else {
            final Object oldValue;
            if (value != null) {
                if ((value instanceof Iterable<?>)
                        && !(value instanceof Properties<?>)) {
                    for (final Object content : (Iterable<?>) value) {
                        if (content instanceof Properties) {
                            throw new IllegalArgumentException(
                                    "Cannot use collections of Properties: "
                                            + content.getClass().getName());
                        }
                    }
                } else if (value instanceof Object[]) {
                    for (final Object content : (Object[]) value) {
                        if (content instanceof Properties) {
                            throw new IllegalArgumentException(
                                    "Cannot use arrays of Properties: "
                                            + content.getClass().getName());
                        }
                    }
                }
                oldValue = properties.put(localKey, value);
                if ((oldValue != null) && builtIn(localKey)) {
                    properties.put(localKey, oldValue);
                    throw new UnsupportedOperationException(
                            "Cannot replace a built-in property: " + localKey);
                }
            } else if (builtIn(localKey)) {
                throw new UnsupportedOperationException(
                        "Cannot remove a built-in property: " + localKey);
            } else {
                oldValue = properties.remove(localKey);
            }
            if (changeTracker != null) {
                changeTracker.onChange(this, localKey, oldValue, value);
            }
        }
    }
}
