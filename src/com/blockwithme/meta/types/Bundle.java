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

import com.blockwithme.meta.Definition;

/**
 * A bundle is a grouping of resources. Typically types, but also media-files.
 *
 * @author monster
 */
public interface Bundle extends Definition<Bundle> {
    /** Returns the bundle version. */
    String version();

    /** Returns the bundle version, as a comparable int. */
    int versionAsInt();

    /** List the types defined in this bundle. */
    Type[] types();

    /** Returns the type by the given name, if any. */
    Type findType(final String name);

    /** List the bundle's dependencies. */
    Dependency[] dependencies();

    /** Returns the dependency with the given name, if any. */
    Dependency findDependency(final String name);
}