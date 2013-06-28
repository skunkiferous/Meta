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

import com.tinkerpop.blueprints.Direction;
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
    @Adjacency(label = "hasProperty", direction = Direction.IN)
    Type getType();

    /** The property's owner type. */
    @Adjacency(label = "hasProperty", direction = Direction.IN)
    void setType(final Type type);

    /** The property type range. */
    @Adjacency(label = "typeRange")
    TypeRange getTypeRange();

    /** The property type range. */
    @Adjacency(label = "typeRange")
    void setTypeRange(final TypeRange typeRange);

    /**
     * Does the owner of this property contains/owns the content of the
     * property? Defaults to true.
     */
    @com.tinkerpop.frames.Property("contains")
    boolean getContains();

    /**
     * Does the owner of this property contains/owns the content of the
     * property? Defaults to true.
     */
    @com.tinkerpop.frames.Property("contains")
    void setContains(final boolean contains);

    /** Is this property persistent? */
    @com.tinkerpop.frames.Property("persistent")
    boolean isPersistent();

    /** Is this property persistent? */
    @com.tinkerpop.frames.Property("persistent")
    void setPersistent(final boolean isPersistent);

    // TODO: We should have access control specifications

    // TODO ...
}
