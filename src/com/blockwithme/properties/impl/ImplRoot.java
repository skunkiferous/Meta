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
import com.blockwithme.properties.Root;

/**
 * ImplRoot must be implemented by Roots, to allow future changes.
 *
 * @author monster
 */
public interface ImplRoot<TIME extends Comparable<TIME>> extends Root<TIME> {

    /** Records changes for the future. They will be applied when the time has come. */
    void onFutureChange(final Properties<TIME> properties,
            final String localKey, final Object newValu, final TIME when);

}
