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

import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * Describes a property of some type.
 *
 * @author monster
 */
@TypeValue("Property")
public interface Property extends Bundled {
    /** The property's owner type. */
    @Adjacency(label = "type")
    Type getType();

    /** The property's owner type. */
    @Adjacency(label = "type")
    void setType(final Type type);

    /** The property type range. */
    @Adjacency(label = "typeRange")
    TypeRange getTypeRange();

    /** The property type range. */
    @Adjacency(label = "typeRange")
    void setTypeRange(final TypeRange typeRange);

    // TODO: We should have access control specifications

    /** The kinds of persistence supported by this property. */
    @com.tinkerpop.frames.Property("persistence")
    String[] getPersistence();

    /** Adds a kind of persistence supported by this property. */
    @com.tinkerpop.frames.Property("persistence")
    void addPersistence(final String persistence);

    /** Removes a kind of persistence supported by this property. */
    @com.tinkerpop.frames.Property("persistence")
    void removePersistence(final String persistence);

    // TODO ...
}
