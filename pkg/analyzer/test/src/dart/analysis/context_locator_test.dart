// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextLocatorImplTest);
  });
}

@reflectiveTest
class ContextLocatorImplTest extends Object with ResourceProviderMixin {
  ContextLocatorImpl contextLocator;

  ContextRoot findRoot(List<ContextRoot> roots, Resource rootFolder) {
    for (ContextRoot root in roots) {
      if (root.root == rootFolder) {
        return root;
      }
    }
    StringBuffer buffer = new StringBuffer();
    buffer.write('Could not find "');
    buffer.write(rootFolder.path);
    buffer.write('" in');
    for (ContextRoot root in roots) {
      buffer.writeln();
      buffer.write('  ');
      buffer.write(root.root);
    }
    fail(buffer.toString());
  }

  File newOptionsFile(String directoryPath) {
    return newFile(resourceProvider.pathContext
        .join(directoryPath, ContextLocatorImpl.ANALYSIS_OPTIONS_NAME));
  }

  File newPackagesFile(String directoryPath) {
    return newFile(resourceProvider.pathContext
        .join(directoryPath, ContextLocatorImpl.PACKAGES_FILE_NAME));
  }

  void setUp() {
    contextLocator = new ContextLocatorImpl(resourceProvider: resourceProvider);
  }

  void test_locateRoots_multiple_dirAndNestedDir() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');

    List<ContextRoot> roots = contextLocator
        .locateRoots([outerRootFolder.path, innerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndNestedFile() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    File testFile = newFile('/test/outer/examples/inner/test.dart');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path, testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingDir() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File outer1OptionsFile = newOptionsFile('/test/outer1');
    File outer1PackagesFile = newPackagesFile('/test/outer1');

    Folder outer2RootFolder = newFolder('/test/outer2');
    File outer2OptionsFile = newOptionsFile('/test/outer2');
    File outer2PackagesFile = newPackagesFile('/test/outer2');

    List<ContextRoot> roots = contextLocator
        .locateRoots([outer1RootFolder.path, outer2RootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, outer1OptionsFile);
    expect(outer1Root.packagesFile, outer1PackagesFile);

    ContextRoot outer2Root = findRoot(roots, outer2RootFolder);
    expect(outer2Root.includedPaths, unorderedEquals([outer2RootFolder.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, outer2OptionsFile);
    expect(outer2Root.packagesFile, outer2PackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingFile() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File outer1OptionsFile = newOptionsFile('/test/outer1');
    File outer1PackagesFile = newPackagesFile('/test/outer1');

    File outer2OptionsFile = newOptionsFile('/test/outer2');
    File outer2PackagesFile = newPackagesFile('/test/outer2');
    File testFile = newFile('/test/outer2/test.dart');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outer1RootFolder.path, testFile.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, outer1OptionsFile);
    expect(outer1Root.packagesFile, outer1PackagesFile);

    ContextRoot outer2Root = findRoot(roots, testFile);
    expect(outer2Root.includedPaths, unorderedEquals([testFile.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, outer2OptionsFile);
    expect(outer2Root.packagesFile, outer2PackagesFile);
  }

  void test_locateRoots_multiple_fileAndSiblingFile() {
    ContextRoot findRootFromIncluded(
        List<ContextRoot> roots, String includedPath) {
      for (ContextRoot root in roots) {
        if (root.includedPaths.contains(includedPath)) {
          return root;
        }
      }
      StringBuffer buffer = new StringBuffer();
      buffer.write('Could not find "');
      buffer.write(includedPath);
      buffer.write('" in');
      for (ContextRoot root in roots) {
        buffer.writeln();
        buffer.write('  ');
        buffer.write(root.root);
      }
      fail(buffer.toString());
    }

    File optionsFile = newOptionsFile('/test/root');
    File packagesFile = newPackagesFile('/test/root');
    File testFile1 = newFile('/test/root/test1.dart');
    File testFile2 = newFile('/test/root/test2.dart');

    List<ContextRoot> roots =
        contextLocator.locateRoots([testFile1.path, testFile2.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRootFromIncluded(roots, testFile1.path);
    expect(outer1Root.includedPaths, unorderedEquals([testFile1.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, optionsFile);
    expect(outer1Root.packagesFile, packagesFile);

    ContextRoot outer2Root = findRootFromIncluded(roots, testFile2.path);
    expect(outer2Root.includedPaths, unorderedEquals([testFile2.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, optionsFile);
    expect(outer2Root.packagesFile, packagesFile);
  }

  void test_locateRoots_nested_excluded_dot() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder excludedFolder = newFolder('/test/outer/.examples');
    newOptionsFile('/test/outer/.examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([excludedFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_excluded_explicit() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder excludedFolder = newFolder('/test/outer/examples');
    newOptionsFile('/test/outer/examples/inner');

    List<ContextRoot> roots = contextLocator.locateRoots([outerRootFolder.path],
        excludedPaths: [excludedFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([excludedFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_excluded_packages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder excludedFolder = newFolder('/test/outer/packages');
    newOptionsFile('/test/outer/packages/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([excludedFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_multiple() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder inner1RootFolder = newFolder('/test/outer/examples/inner1');
    File inner1OptionsFile = newOptionsFile('/test/outer/examples/inner1');
    Folder inner2RootFolder = newFolder('/test/outer/examples/inner2');
    File inner2PackagesFile = newPackagesFile('/test/outer/examples/inner2');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path]);
    expect(roots, hasLength(3));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths,
        unorderedEquals([inner1RootFolder.path, inner2RootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot inner1Root = findRoot(roots, inner1RootFolder);
    expect(inner1Root.includedPaths, unorderedEquals([inner1RootFolder.path]));
    expect(inner1Root.excludedPaths, isEmpty);
    expect(inner1Root.optionsFile, inner1OptionsFile);
    expect(inner1Root.packagesFile, outerPackagesFile);

    ContextRoot inner2Root = findRoot(roots, inner2RootFolder);
    expect(inner2Root.includedPaths, unorderedEquals([inner2RootFolder.path]));
    expect(inner2Root.excludedPaths, isEmpty);
    expect(inner2Root.optionsFile, outerOptionsFile);
    expect(inner2Root.packagesFile, inner2PackagesFile);
  }

  void test_locateRoots_nested_options() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile = newOptionsFile('/test/outer/examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_optionsAndPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile = newOptionsFile('/test/outer/examples/inner');
    File innerPackagesFile = newPackagesFile('/test/outer/examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newOptionsFile('/test/outer');
    File outerPackagesFile = newPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerPackagesFile = newPackagesFile('/test/outer/examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots([outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, outerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_single_dir_directOptions_directPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newOptionsFile('/test/root');
    File packagesFile = newPackagesFile('/test/root');

    List<ContextRoot> roots = contextLocator.locateRoots([rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_directOptions_inheritedPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newOptionsFile('/test/root');
    File packagesFile = newPackagesFile('/test');

    List<ContextRoot> roots = contextLocator.locateRoots([rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_inheritedOptions_directPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newOptionsFile('/test');
    File packagesFile = newPackagesFile('/test/root');

    List<ContextRoot> roots = contextLocator.locateRoots([rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_inheritedOptions_inheritedPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newOptionsFile('/test');
    File packagesFile = newPackagesFile('/test');

    List<ContextRoot> roots = contextLocator.locateRoots([rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_file_inheritedOptions_directPackages() {
    File optionsFile = newOptionsFile('/test');
    File packagesFile = newPackagesFile('/test/root');
    File testFile = newFile('/test/root/test.dart');

    List<ContextRoot> roots = contextLocator.locateRoots([testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, testFile);
    expect(package1Root.includedPaths, unorderedEquals([testFile.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }
}
