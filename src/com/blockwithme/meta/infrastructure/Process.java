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

import com.blockwithme.meta.Definition;
import com.blockwithme.meta.Dynamic;
import com.blockwithme.meta.types.Bundle;

/**
 * A process. It could be a Java Virtual Machine.
 *
 * It could run any number of applications. Any access to it goes over an
 * application.
 *
 * @author monster
 */
public interface Process extends Definition<Process> {
    /** Returns the process type. */
    ProcessType getProcessType();

    /** The applications *currently* running in this process. */
    @Dynamic
    Application[] applications();

    /** Returns the application with the given name, if any. */
    Application findApplication(final String name);

    /** Returns all the currently available bundles. */
    @Dynamic
    Bundle[] bundles();

    /**
     * Returns the bundles with the given name, if any.
     * There could be multiple versions available!
     */
    Bundle[] findBundle(final String name);
}
