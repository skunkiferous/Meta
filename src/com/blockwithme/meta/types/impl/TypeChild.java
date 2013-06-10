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

import com.blockwithme.meta.Definition;
import com.blockwithme.meta.impl.BaseDefinition;

/**
 * @author monster
 *
 */
public class TypeChild<C extends Definition<C>> extends BaseDefinition<C> {

    public TypeImpl type() {
        return (TypeImpl) getProperty("type");
    }

    /** Sets the type */
    public C type(final TypeImpl value) {
        return setProperty("type", value);
    }

    /** Returns the "unique key" to this definition. */
    @Override
    public String key() {
        return type().key() + "|" + name();
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("type", TypeImpl.class);
        super._postInit();
        postInit(type());
    }
}
