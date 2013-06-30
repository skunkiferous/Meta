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
import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.modules.javahandler.JavaHandler;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * The type range defines the range of possible types accepted by a
 * non-primitive, non-Data, property.
 *
 * A type range should not specify any Implementation type.
 *
 * TODO: Can we represent the fact, that an instance could be of multiple types
 * at the same time? (Composition)
 *
 * @author monster
 */
@TypeValue("TypeRange")
public interface TypeRange extends Bundled {

    /** Is the actual instance preserved, implying any child type is accepted? */
    @Property("actualInstance")
    boolean isActualInstance();

    /** Defines if the actual instance preserved, implying any child type is accepted. */
    @Property("actualInstance")
    void setActualInstance(final boolean actualInstance);

    /** The declared type of this property. */
    @Adjacency(label = "defaultsTo")
    Type getDeclaredType();

    /** The declared type of this property. */
    @Adjacency(label = "defaultsTo")
    void setDeclaredType(final Type defaultType);

    /** Is only the the declared type accepted, and only the data value preserved? */
    @Property("exact")
    boolean isExact();

    /** Is only the the declared type accepted, and only the data value preserved? */
    @Property("exact")
    void setExact(final boolean isExact);

    /**
     * Lists the explicitly accepted children type, of the declared type.
     */
    @Adjacency(label = "accepts")
    Iterable<Type> getAcceptedTypes();

    /** Adds a new accepted child. */
    @Adjacency(label = "accepts")
    void addAcceptedType(final Type type);

    /** Removes an accepted child. */
    @Adjacency(label = "accepts")
    void removeAcceptedTypet(final Type type);

    /**
     * Lists the explicitly rejected children type, of the declared type.
     */
    @Adjacency(label = "rejects")
    Iterable<Type> getRejectedTypes();

    /** Adds a new rejected child. */
    @Adjacency(label = "rejects")
    void addRejectedType(final Type type);

    /** Removes an rejected child. */
    @Adjacency(label = "rejects")
    void removeRejectedType(final Type type);

//
//    /** Returns the type filters. */
//    @Property("filters")
//    TypeFilter[] getAcceptFilters();
//
//    /** Adds a new filter. */
//    @Property("filters")
//    void addAcceptFilter(final TypeFilter filter);
//
//    /** Removes an filter. */
//    @Property("filters")
//    void removeAcceptFilter(final TypeFilter filter);

    /** Is the given type an accepted child type? */
    @JavaHandler
    boolean accept(final Type type);
}
