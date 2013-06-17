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
import com.blockwithme.properties.Root;

/**
 * Default Root implementation.
 *
 * It must manage the time, and the postponed updates.
 *
 * @author monster
 */
public class RootImpl<TIME extends Comparable<TIME>> extends
        PropertiesImpl<TIME> implements Root<TIME> {

    /** The current time. */
    private TIME now;

    /** Buffered future changes. */
    private final TreeMap<TIME, List<Change<TIME>>> changes = new TreeMap<>();

    /**
     * @param now
     */
    public RootImpl(final TIME now) {
        super(null, "", now);
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
            // Perform buffered updates
            for (final TIME when : new ArrayList<>(changes.keySet())) {
                if (newTime.compareTo(when) >= 0) {
                    for (final Change<TIME> change : changes.remove(when)) {
                        change.perform();
                    }
                }
            }
            now = newTime;
        }
    }

    /** Records a future change. */
    private void recordChange(final Change<TIME> change) {
        List<Change<TIME>> changeList = changes.get(change.when);
        if (changeList == null) {
            changeList = new ArrayList<>();
            changes.put(change.when, changeList);
        }
        changeList.add(change);
    }

    /** Receives changes that will only be applied in the future. */
    public final void onFutureChange(final Properties<TIME> setter,
            final Properties<TIME> properties, final String localKey,
            final Object newValue, final boolean forceWrite, final TIME when) {
        if (now.compareTo(when) >= 0) {
            // OK time was past/present, so perform now
            properties.set(setter, localKey, newValue, null, forceWrite);
        } else {
            // Save for later
            final Change<TIME> change = new Change<TIME>();
            change.properties = properties;
            change.localKey = localKey;
            change.newValue = newValue;
            change.setter = setter;
            change.forceWrite = forceWrite;
            change.when = when;
            recordChange(change);
        }
    }

    /** Receives changes that will only be applied in the future. */
    public final void onFutureChange(final Change<TIME> change) {
        if (now.compareTo(change.when) >= 0) {
            // OK time was past/present, so perform now
            change.perform();
        } else {
            // Save for later
            recordChange(change);
        }
    }

    /** Informs the root of changes. */
    public void onChange(final Properties<TIME> setter,
            final Properties<TIME> properties, final String localKey,
            final Object oldValue, final Object newValue) {
        // NOP
    }

    /**
     * Returns true, if the first instance has lower priority as the second
     * instance. The default implementation always returns false, which results
     * in the last-writer-wins semantic.
     */
    public boolean lowerPriority(final Properties<TIME> setter1,
            final Properties<TIME> setter2) {
        return false;
    }
}
