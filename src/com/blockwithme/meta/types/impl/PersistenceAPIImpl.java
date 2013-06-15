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
import com.blockwithme.meta.types.PersistenceAPI;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;

/**
 * @author monster
 *
 */
public class PersistenceAPIImpl<SERIALIZER> extends
        BundledDefinition<PersistenceAPI<SERIALIZER>> implements
        PersistenceAPI<SERIALIZER> {

    /**
     * @param theApp
     * @param theName
     */
    protected PersistenceAPIImpl(final Bundle theBundle, final String theName) {
        super(theBundle, theName);
    }

    /** Returns the "unique key" to this definition. */
    @Override
    public String key() {
        return bundle().key() + "|PersistenceAPI|" + name();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.PersistenceAPI#serializerFor(com.blockwithme.meta.types.Type)
     */
    @Override
    public SERIALIZER serializerFor(final Type type) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("TODO");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.PersistenceAPI#serializerFor(com.blockwithme.meta.types.Property)
     */
    @Override
    public SERIALIZER serializerFor(final Property property) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("TODO");
    }

}
