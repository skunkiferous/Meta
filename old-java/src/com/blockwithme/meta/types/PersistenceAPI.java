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
package com.blockwithme.meta.types;

import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * Represents some persistence API.
 *
 * @author monster
 */
@TypeValue("PersistenceAPI")
public interface PersistenceAPI<SERIALIZER> extends Service {

    /**
     * Returns the serializer to use for the given type.
     *
     * Returns null if serialization is not supported (for this type).
     */
    // TODO
//    SERIALIZER getSerializerFor(final Type type);

    /**
     * Returns the serializer to use for the given property.
     *
     * Returns null if serialization is not supported (for this property).
     */
    // TODO
//    SERIALIZER serializerFor(final Property property);
}
