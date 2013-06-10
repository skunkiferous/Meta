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

import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.TypeRange;

/**
 * @author monster
 *
 */
public class PropertyImpl extends TypeChild<Property> implements Property {
    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Property#typeRange()
     */
    @Override
    public TypeRange typeRange() {
        return (TypeRange) getProperty("typeRange");
    }

    public PropertyImpl typeRange(final TypeRange newTypeRange) {
        return (PropertyImpl) setProperty("typeRange", newTypeRange);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Property#persistence()
     */
    @Override
    public String[] persistence() {
        return (String[]) getProperty("persistence");
    }

    public PropertyImpl persistence(final String[] newPersistence) {
        return (PropertyImpl) setProperty("persistence", newPersistence);
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("typeRange", TypeRange.class);
        checkProp("persistence", String[].class);
        super._postInit();
        postInit(typeRange());
    }
}
