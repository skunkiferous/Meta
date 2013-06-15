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

import java.util.Comparator;

import com.blockwithme.meta.Configurable;
import com.blockwithme.meta.Definition;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Bundled;

/**
 * An application is a specific *application configuration* of an application,
 * running on a specific execution environment. It is defined by its bundles,
 * and other resources, as well as it's execution environment.
 *
 * Application instances with the same name, refer to the same logical
 * application.
 *
 * We assume Connectors are unchangeable, once created...
 *
 * @author monster
 */
public interface Application extends Definition<Application>,
        Bundled<Application> {
    /** The "root" application bundle, which can use any number of other bundles. */
    @Override
    Bundle bundle();

    /** Returns the current application time. */
    long time();

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    int distanceFromRoot(final Bundle bundle);

    /** Returns a Bundle Comparator. */
    Comparator<Bundle> bundleComparator();

    /** Is this a distributed application? */
    boolean distributed();

    /** Is this a JVM-based application? */
    boolean javaApp();

    /** Returns the application state. */
    AppState appState();

    /** Allows adding empty property names slots at the end of the array. */
    String[] properties(final Configurable<?> cfg, final int freeslots);

    /**
     * @param cfg
     * @param time
     * @param name
     * @return
     */
    Object getProperty(final Configurable<?> cfg, final Long time,
            final String name);

    /** Sets a property. */
    Application setProperty(final Configurable<?> cfg, final Bundle bundle,
            final long time, final String name, final Object value);
}
