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

import java.util.Objects;

import com.blockwithme.properties.Generator;
import com.blockwithme.properties.Properties;

/**
 * A link simply returns some other property from some (possibly other) Properties.
 *
 * @author monster
 */
public class Link implements Generator {

    /** The link path. */
    private final String path;

    /** Creates a link with the given path */
    public Link(final String path) {
        this.path = Objects.requireNonNull(path);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Generator#generate(com.blockwithme.properties.Properties, java.lang.String, java.lang.Class)
     */
    @Override
    public <E> E generate(final Properties<?> prop, final String name,
            final Class<E> expectedType) {
        return prop.find(path, expectedType);
    }
}
