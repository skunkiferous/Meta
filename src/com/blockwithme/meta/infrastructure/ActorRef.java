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
package com.blockwithme.meta.infrastructure;

import com.blockwithme.meta.TypedVertex;
import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * An actor is an active component, that can send and receive messages, and
 * runs within a JVM. Some actors can migrate from one JVM to another, within
 * the same Application.
 *
 * @author monster
 */
@TypeValue("ActorRef")
public interface ActorRef extends TypedVertex {
    /** The actor's globally unique ID. */
    @Property("actorId")
    long getActorId();

    /** Sets the actor's globally unique ID. */
    @Property("actorId")
    void setActorId(final long id);
}
