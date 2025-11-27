'use client';

import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { ExclamationTriangleIcon } from '@heroicons/react/24/outline';

interface InactivityWarningProps {
  isOpen: boolean;
  timeRemaining: number; // in seconds
  onExtend: () => void;
  onLogout: () => void;
}

export default function InactivityWarning({
  isOpen,
  timeRemaining,
  onExtend,
  onLogout,
}: InactivityWarningProps) {
  const minutes = Math.floor(timeRemaining / 60);
  const seconds = timeRemaining % 60;

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={() => {}}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black bg-opacity-50" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4 text-center">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center space-x-4 mb-4">
                  <div className="flex-shrink-0">
                    <ExclamationTriangleIcon className="h-10 w-10 text-amber-500" />
                  </div>
                  <div>
                    <Dialog.Title
                      as="h3"
                      className="text-lg font-medium leading-6 text-gray-900"
                    >
                      Session Timeout Warning
                    </Dialog.Title>
                  </div>
                </div>

                <div className="mt-4">
                  <p className="text-sm text-gray-500 mb-4">
                    You've been inactive for a while. For security reasons, you'll be
                    automatically logged out in:
                  </p>
                  
                  <div className="text-center mb-6">
                    <div className="inline-flex items-center justify-center px-6 py-4 bg-amber-50 rounded-lg border-2 border-amber-200">
                      <span className="text-3xl font-bold text-amber-600">
                        {String(minutes).padStart(2, '0')}:
                        {String(seconds).padStart(2, '0')}
                      </span>
                    </div>
                  </div>

                  <p className="text-sm text-gray-600 mb-6 text-center">
                    Click "Stay Logged In" to continue your session.
                  </p>
                </div>

                <div className="flex space-x-3 mt-6">
                  <button
                    type="button"
                    onClick={onLogout}
                    className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
                  >
                    Logout Now
                  </button>
                  <button
                    type="button"
                    onClick={onExtend}
                    className="flex-1 px-4 py-2 text-sm font-medium text-white bg-[#00695C] rounded-md hover:bg-[#004D40] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#00695C] transition-colors"
                  >
                    Stay Logged In
                  </button>
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}

