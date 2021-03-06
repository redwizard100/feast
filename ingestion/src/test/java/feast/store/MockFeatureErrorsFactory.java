/*
 * Copyright 2019 The Feast Authors
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
 *
 */

package feast.store;

import com.google.auto.service.AutoService;
import feast.store.errors.FeatureErrorsFactory;

@AutoService(FeatureErrorsFactory.class)
public class MockFeatureErrorsFactory extends MockFeatureStore implements
    FeatureErrorsFactory {
  public static final String MOCK_ERRORS_STORE_TYPE = "errors.mock";

  public MockFeatureErrorsFactory() {
    super(MOCK_ERRORS_STORE_TYPE);
  }
}
