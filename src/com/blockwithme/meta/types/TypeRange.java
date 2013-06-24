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
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

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

    /**
     * Does the owner of this property contains/owns the content of the
     * property? Defaults to true.
     */
    @Property("contains")
    boolean getContains();

    /**
     * Does the owner of this property contains/owns the content of the
     * property? Defaults to true.
     */
    @Property("contains")
    void setContains(final boolean contains);

    /**
     * Lists the explicitly accepted children type, of the declared type.
     * An empty list means an exact type match.
     */
    @Adjacency(label = "accepts")
    Type[] getChildren();

    /** Adds a new accepted child. */
    @Adjacency(label = "accepts")
    void addChild(final Type type);

    /** Removes an accepted child. */
    @Adjacency(label = "accepts")
    void removeChild(final Type type);

    /** Returns the accepted child with the given name, if any. */
    @GremlinGroovy("it.out('accepts').has('name',name)")
    Type findChild(@GremlinParam("name") final String name);

    /** Returns the type filters. */
    @Property("filters")
    TypeFilter[] getTypeFilters();

    /** Adds a new filter. */
    @Property("filters")
    void addTypeFilter(final TypeFilter filter);

    /** Removes an filter. */
    @Property("filters")
    void removeTypeFilter(final TypeFilter filter);

    // TODO
    /** Is the given type an accepted child type? */
//    boolean accept(final Type type);
}
