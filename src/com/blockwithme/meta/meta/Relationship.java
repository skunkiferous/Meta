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
package com.blockwithme.meta.meta;

import com.blockwithme.meta.Definition;

/**
 * Represents a relationship between concepts.
 *
 * @author monster
 */
public interface Relationship extends Definition<Relationship> {
    /** All relationships have a reciprocal, which could be itself. */
    Relationship reciprocal();

    /** The relationship participants. */
    Participant[] participants();

    /** Returns the Participant with the given name, if any. */
    Participant findParticipant(final String name);
}