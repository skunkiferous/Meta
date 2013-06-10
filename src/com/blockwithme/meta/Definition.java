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

/**
 * A definition has a name (the uniqueness scope of which depends on the
 * specific definition type), and can have any number of generic properties,
 * in addition to the properties provided over it's interface.
 *
 * Definitions can be sorted by name.
 *
 * @author monster
 */
public interface Definition<D extends Definition<D>> extends Configurable<D>,
        Comparable<D> {
    /** The name of this definition. */
    String name();
}
