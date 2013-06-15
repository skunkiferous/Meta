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

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.TreeMap;

import com.blockwithme.properties.Properties;

/**
 * Default Root implementation.
 *
 * @author monster
 */
public class RootImpl<TIME extends Comparable<TIME>> extends
        PropertiesImpl<TIME> implements ImplRoot<TIME> {

    /** Represents a future change. */
    private static final class Change<TIME extends Comparable<TIME>> {
        public Properties<TIME> properties;
        public String localKey;
        public Object newValue;
    }

    /** The current time. */
    private TIME now;

    /** Buffered future changes. */
    private final TreeMap<TIME, List<Change<TIME>>> changes = new TreeMap<>();

    /**
     * @param now
     */
    public RootImpl(final TIME now) {
        super(null, "");
        this.now = Objects.requireNonNull(now, "now");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Root#getTime()
     */
    @Override
    public final TIME getTime() {
        return now;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Root#setTime(java.lang.Object)
     */
    @Override
    public final void setTime(final TIME newTime) {
        Objects.requireNonNull(newTime, "newTime");
        final int cmp = now.compareTo(newTime);
        if (cmp > 0) {
            throw new IllegalArgumentException("Time cannot go backward: now="
                    + now + " newTime=" + newTime);
        }
        if (cmp < 0) {
            for (final TIME when : new ArrayList<>(changes.keySet())) {
                if (newTime.compareTo(when) >= 0) {
                    for (final Change<TIME> change : changes.remove(when)) {
                        change.properties.set(change.localKey,
                                change.newValue, null);
                    }
                }
            }
            now = newTime;
        }
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.impl.ImplRoot#onFutureChange(com.blockwithme.properties.Properties, java.lang.String, java.lang.Object)
     */
    @Override
    public final void onFutureChange(final Properties<TIME> properties,
            final String localKey, final Object newValue, final TIME when) {
        if (now.compareTo(when) >= 0) {
            properties.set(localKey, newValue, null);
        } else {
            final Change<TIME> change = new Change<TIME>();
            change.properties = properties;
            change.localKey = localKey;
            change.newValue = newValue;
            List<Change<TIME>> changeList = changes.get(when);
            if (changeList == null) {
                changeList = new ArrayList<>();
                changes.put(when, changeList);
            }
            changeList.add(change);
        }
    }
}
