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
 * Describes the property of some type, which is a container for another type.
 *
 * @author monster
 */
@TypeValue("Container")
public interface Container extends Bundled {
    /** The container. */
    @Adjacency(label = "container")
    Type getContainer();

    /** The container. */
    @Adjacency(label = "container")
    void setContainer(final Type container);

    /** The property. */
    @Adjacency(label = "property")
    Property getProperty();

    /** The property. */
    @Adjacency(label = "property")
    void setProperty(final Property property);
}
