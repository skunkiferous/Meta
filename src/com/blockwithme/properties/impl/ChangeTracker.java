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

import com.blockwithme.properties.Properties;

/**
 * Called when the value of a property changes.
 *
 * @author monster
 */
public interface ChangeTracker<TIME extends Comparable<TIME>> {
    /**
     * Called when the value of a property changes. Null newValue means removed.
     *
     * If localKey is null, the both oldValue and newValue must be null, and
     * this means the Properties object was just created.
     */
    void onChange(final Properties<TIME> properties, final String localKey,
            final Object oldValue, final Object newValue);
}
