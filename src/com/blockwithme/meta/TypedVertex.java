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
package com.blockwithme.meta;

import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.typed.TypeField;

/**
 * TypedVertex is the base class of all vertex.
 * It allows the type information to be preserved when converting the proxy
 * instances to/from pure vertex.
 *
 * @author monster
 */
@TypeField("class")
public interface TypedVertex extends Vertex {

    /** Returns the description of this vertex. */
    @GremlinGroovy(value = "com.blockwithme.meta.types.Statics.toString(it)", frame = false)
    String getString();

}
