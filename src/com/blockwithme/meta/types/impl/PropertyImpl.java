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
package com.blockwithme.meta.types.impl;

import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.TypeRange;
import com.blockwithme.properties.impl.ImplGraph;

/**
 * @author monster
 *
 */
public class PropertyImpl extends TypeChild<Property> implements Property {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected PropertyImpl(final ImplGraph<Long> graph, final String localKey,
            final Long when) {
        super(graph, localKey, when);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Property#typeRange()
     */
    @Override
    public TypeRange typeRange() {
        return get("typeRange", TypeRange.class);
    }

    public PropertyImpl typeRange(final Bundle bundle, final long time,
            final TypeRange newTypeRange) {
        set(bundle, "typeRange", newTypeRange, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Property#persistence()
     */
    @Override
    public String[] persistence() {
        return get("persistence", String[].class);
    }

    public PropertyImpl persistence(final Bundle bundle, final long time,
            final String[] newPersistence) {
        set(bundle, "persistence", newPersistence, time, false);
        return this;
    }
}
